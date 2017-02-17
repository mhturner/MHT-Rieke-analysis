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
    % -seedName (string, 'noiseSeed') from the protocol
    % -keepExcPolarity (logical, true) true - don't do any polarity flips
    %                   to responses (i.e. keep exc. inward). False - flip exc so both e and
    %                   i are positive (pA)
    % -downSampleAtNoiseRate (logical, false) 
    % MHT 12/5/16
    ip = inputParser;
    ip.addRequired('epoch',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpoch'));
    ip.addRequired('recordingType',@ischar);
    addParameter(ip,'seedName','noiseSeed',@ischar);
    addParameter(ip,'keepExcPolarity',true,@islogical);
    addParameter(ip,'downSampleAtNoiseRate',false,@islogical);
    
    ip.parse(epoch,recordingType,varargin{:});
    epoch = ip.Results.epoch;
    recordingType = ip.Results.recordingType;
    seedName = ip.Results.seedName;
    keepExcPolarity = ip.Results.keepExcPolarity;
    downSampleAtNoiseRate = ip.Results.downSampleAtNoiseRate;

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
        if ~isempty(strfind(recordingType,'conductance')) %estimate conductance, nS
            if ~isempty(strfind(recordingType,'exc'))
                DF = -60; %mV
            elseif ~isempty(strfind(recordingType,'inh'))
                DF = 60; %mV
            end
            currentResponse = baselineSubtracted ./ DF; %nS
        else %keep it in (pA)
            if and(strcmp(recordingType,'exc'), keepExcPolarity)

            else
                baselineSubtracted = -baselineSubtracted; 
            end
            currentResponse = baselineSubtracted;
        end

    else
        currentResponse = currentData;
        warning('Unrecognized recording type, no processing done on traces')
    end

    %entire traces, with pre and tail points...
    res.wholeTrace.response = currentResponse;
    res.wholeTrace.timeVector = (1:size(currentResponse,2))./ sampleRate;

    %get noise stimulus
    %timing stuff:
    preTime = baselineTime; %msec
    stimTime = epoch.protocolSettings('stimTime'); %msec
    frameDwell = epoch.protocolSettings('frameDwell');
    lightCrafterFlag = epoch.protocolSettings.keySet.contains('background:LightCrafter Stage@localhost:lightCrafterPatternRate');
    if ~lightCrafterFlag
        lightCrafterFlag = epoch.protocolSettings.keySet.contains('background:LightCrafter_Stage@localhost:lightCrafterPatternRate');
    end
    frameRate = epoch.protocolSettings('background:Microdisplay Stage@localhost:monitorRefreshRate');
    if isempty(frameRate)
        frameRate = epoch.protocolSettings('background:Microdisplay_Stage@localhost:monitorRefreshRate');
    end
    FMdata = (riekesuite.getResponseVector(epoch,'Frame Monitor'))';
    frameTimes = getFrameTiming(FMdata,lightCrafterFlag);
    %trim data to stim size:
    preFrames = frameRate*(preTime/1000);
    firstStimFrameFlip = frameTimes(preFrames);
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
    binnedStimulus = zeros(1,floor(stimFrames/frameDwell));
    binnedResponse = zeros(1,floor(stimFrames/frameDwell));
    for ii = 1:floor(stimFrames/frameDwell)
        binnedStimulus(ii) = noiseStdv * noiseStream.randn;
        binnedResponse(ii) = mean(currentResponse(round((ii-1)*chunkLen + 1) : round(ii*chunkLen)));
    end
    res.updateRate = (frameRate/frameDwell); %hz

    if (downSampleAtNoiseRate)
        res.stimulus = binnedStimulus;
        res.response = binnedResponse;
        res.sampleRate = res.updateRate;
    else
        res.stimulus = kron(binnedStimulus,ones(1,round(chunkLen)));
        res.response = currentResponse(1:length(res.stimulus));
        res.sampleRate = sampleRate;
    end
    
    res.wholeTrace.stimulus = [zeros(1,baselinePoints), ...
            kron(binnedStimulus,ones(1,round(chunkLen))), ...
            zeros(1,tailPoints)];
end