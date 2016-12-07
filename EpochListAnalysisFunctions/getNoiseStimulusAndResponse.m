function res = getNoiseStimulusAndResponse(epoch,recordingType,varargin)
    % USAGE: trace = getNoiseStimulusAndResponse(epoch,recordingType,varargin)
    % -epoch is a riekesuite epoch
    % -recordingType is: 'extracellular' (default) - PSTH
    %                   'iClamp, spikes' - PSTH
    %                   'iClamp, subthreshold' - sub-threshold Vm
    %                           (spikes filtered out)
    %                   'iClamp' - Vm (mV), typically analog cells
    %                   'exc' or 'inh' - current (pA)
    %                   'exc, conductance' or 'inh, conductance' -
    %                           estimated conductance (DF  = 60 mV)
    % -seedName is from the protocol, as a string. E.g. 'noiseSeed' or
    %                   'centerNoiseSeed'
    % MHT 12/5/16
    ip = inputParser;
    ip.addRequired('epoch',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpoch'));
    ip.addRequired('recordingType',@ischar);
    addParameter(ip,'seedName','noiseSeed',@ischar);
    
    ip.parse(epoch,recordingType,varargin{:});
    epoch = ip.Results.epoch;
    recordingType = ip.Results.recordingType;
    seedName = ip.Results.seedName;

    sampleRate = epoch.protocolSettings('sampleRate'); %Hz
    baselineTime = epoch.protocolSettings('preTime'); %msec
    tailTime = epoch.protocolSettings('tailTime'); %msec
    baselinePoints = (baselineTime / 1e3) * sampleRate; %msec -> datapoints
    tailPoints = (tailTime / 1e3) * sampleRate; %msec -> datapoints
    
    %load data
    amp = epoch.protocolSettings.get('amp');
    currentData = (riekesuite.getResponseVector(epoch,amp))';
    
    %process traces
    if strcmp(recordingType, 'extracellular')
        [SpikeTimes, ~, ~] = ...
            SpikeDetector(currentData);
        currentResponse = zeros(size(currentData));
        currentResponse(SpikeTimes) = 1; %spike binary train
    elseif strcmp(recordingType,'iClamp, spikes')
        [SpikeTimes, ~]...
            = CurrentClampSpikeDetector(currentData,'Threshold',-20);
        currentResponse = zeros(size(currentData));
        currentResponse(SpikeTimes) = 1; %spike binary train
    elseif strcmp(recordingType,'iClamp, subthreshold')
        %median filter (width 5 msec) to remove spikes
        currentResponse = medfilt1(currentData,(5 / 1e3) * sampleRate,[],2);
    elseif strcmp(recordingType,'iClamp')
        currentResponse = currentData;
    elseif or(~isempty(strfind(recordingType,'exc')),~isempty(strfind(recordingType,'inh')))
        baseline = mean(currentData(:,1:baselinePoints),2);
        baselineSubtracted = currentData - baseline;
        if strcmp(recordingType,'exc') %sign flip inward currents
            baselineSubtracted = -baselineSubtracted; 
        elseif strcmp(recordingType,'inh')

        end
        currentResponse = baselineSubtracted;
    else
        currentResponse = currentData;
        warning('Unrecognized recording type, no processing done on traces')
    end

    res.timeVector = (1:size(currentResponse,2))./ sampleRate;
    res.response = currentResponse;

    %get noise stimulus
    %timing stuff:
    preTime = baselineTime; %msec
    stimTime = epoch.protocolSettings('stimTime'); %msec
    frameDwell = epoch.protocolSettings('frameDwell');
    lightCrafterFlag = epoch.protocolSettings.keySet.contains('background:LightCrafter Stage@localhost:lightCrafterPatternRate');
    frameRate = epoch.protocolSettings('background:Microdisplay Stage@localhost:monitorRefreshRate');
    FMdata = (riekesuite.getResponseVector(epoch,'Frame Monitor'))';
    frameTimes = getFrameTiming(FMdata,lightCrafterFlag);
    %trim data to stim size:
    preFrames = frameRate*(preTime/1000);
    firstStimFrameFlip = frameTimes(preFrames+1);
    currentResponse = currentResponse(firstStimFrameFlip:end); %cut out pre-frames

    %reconstruct noise stimulus:
    currentNoiseSeed = epoch.protocolSettings(seedName);  
    noiseStdv = epoch.protocolSettings('noiseStdv');

    %reconstruct stimulus trajectories...
    stimFrames = round(frameRate * (stimTime/1e3));
    %reset random stream to recover stim trajectories
    noiseStream = RandStream('mt19937ar', 'Seed', currentNoiseSeed);
    % get stim trajectories and response in frame updates
    chunkLen = frameDwell*mean(diff(frameTimes));
    res.binnedStimulus = zeros(1,floor(stimFrames/frameDwell));
    res.binnedResponse = zeros(1,floor(stimFrames/frameDwell));
    for ii = 1:floor(stimFrames/frameDwell)
        res.binnedStimulus(ii) = noiseStdv * noiseStream.randn;
        res.binnedResponse(ii) = mean(currentResponse(round((ii-1)*chunkLen + 1) : round(ii*chunkLen)));
    end
    res.stimulus = [zeros(1,baselinePoints), ...
        kron(res.binnedStimulus,ones(1,round(chunkLen))), ...
        zeros(1,tailPoints)];
    res.updateRate = (frameRate/frameDwell); %hz

end