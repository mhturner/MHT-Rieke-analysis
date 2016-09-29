function res = getLinearFilterAndPrediction(epochList,recordingType,varargin)
    % USAGE: trace = getLinearFilterAndPrediction(epochList,recordingType,seedName,numberOfBins)
    % -epochList is a riekesuite epoch list
    % -recordingType is: 'extracellular' (default) - PSTH
    %                   'iClamp, spikes' - PSTH
    %                   'iClamp, subthreshold' - sub-threshold Vm
    %                           (spikes filtered out)
    %                   'iClamp' - Vm (mV), typically analog cells
    %                   'exc' or 'inh' - current (pA)
    %                   'exc, conductance' or 'inh, conductance' -
    %                           estimated conductance (DF  = 60 mV)
    % -seedName is from the protocol, as a string. E.g. 'noiseSeed' or
    %                   'centerSeed'
    % -numberOfBins is for the nonlinearity
    % MHT 8/5/16
    ip = inputParser;
    ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
    ip.addRequired('recordingType',@ischar);
    addParameter(ip,'seedName','noiseSeed',@ischar);
    addParameter(ip,'numberOfBins',20,@isnumeric);
    
    ip.parse(epochList,recordingType,varargin{:});
    epochList = ip.Results.epochList;
    recordingType = ip.Results.recordingType;
    seedName = ip.Results.seedName;
    numberOfBins = ip.Results.numberOfBins;
    
    epochList = sortEpochList_time(epochList);

    sampleRate = epochList.firstValue.protocolSettings('sampleRate'); %Hz
    baselineTime = epochList.firstValue.protocolSettings('preTime'); %msec
    baselinePoints = (baselineTime / 1e3) * sampleRate; %msec -> datapoints
    lightCrafterFlag = epochList.firstValue.protocolSettings.keySet.contains('background:LightCrafter Stage@localhost:lightCrafterPatternRate');
    
    res.n = epochList.length;
    allStimuli = [];
    allResponses = [];
    for e = 1:epochList.length
        currentEpoch = epochList.elements(e);
        %load data
        amp = currentEpoch.protocolSettings.get('amp');
        currentData = (riekesuite.getResponseVector(currentEpoch,amp))';
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
        
        %timing stuff:
        preTime = baselineTime; %msec
        stimTime = epochList.firstValue.protocolSettings('stimTime'); %msec
        frameDwell = currentEpoch.protocolSettings('frameDwell');
        frameRate = currentEpoch.protocolSettings('background:Microdisplay Stage@localhost:monitorRefreshRate');
        FMdata = (riekesuite.getResponseVector(currentEpoch,'Frame Monitor'))';
        frameTimes = getFrameTiming(FMdata,lightCrafterFlag);
        %trim data to stim size:
        preFrames = frameRate*(preTime/1000);
        firstStimFrameFlip = frameTimes(preFrames+1);
        currentResponse = currentResponse(firstStimFrameFlip:end); %cut out pre-frames
        
        %reconstruct noise stimulus:
        filterLen = 800; %msec, length of linear filter to compute
        %fraction of noise update rate at which to cut off filter spectrum
        freqCutoffFraction = 1;
        currentNoiseSeed = currentEpoch.protocolSettings(seedName);  
        noiseStdv = currentEpoch.protocolSettings('noiseStdv');

        %reconstruct stimulus trajectories...
        stimFrames = round(frameRate * (stimTime/1e3));
        stimulus = zeros(1,floor(stimFrames/frameDwell));
        response = zeros(1, floor(stimFrames/frameDwell));
        %reset random stream to recover stim trajectories
        noiseStream = RandStream('mt19937ar', 'Seed', currentNoiseSeed);
        % get stim trajectories and response in frame updates
        chunkLen = frameDwell*mean(diff(frameTimes));
        for ii = 1:floor(stimFrames/frameDwell)
            allStimuli(e,ii) = noiseStdv * noiseStream.randn;
            allResponses(e,ii) = mean(currentResponse(round((ii-1)*chunkLen + 1) : round(ii*chunkLen)));
        end
        
        
    end
    updateRate = (frameRate/frameDwell); %hz
    
    LinearFilter = LinFilterFinder(allStimuli,allResponses, updateRate, freqCutoffFraction*updateRate);
    filterPts = (filterLen/1000)*updateRate;
    
    tempResp = reshape(allResponses',1,numel(allResponses));
    tempStim = reshape(allStimuli',1,numel(allStimuli));
    linearPrediction = conv(tempStim,LinearFilter);
    linearPrediction = linearPrediction(1:length(tempStim));
    
    res.stimulus = tempStim;
    res.LinearFilter = LinearFilter(1:filterPts);
    res.filterTimeVector = (1:filterPts) ./ updateRate; %sec
    res.measuredResponse = tempResp;
    res.generatorSignal = linearPrediction;
    
    % get nonlinearity
    [n,binMean,binSTD,binID] = histcounts_equallyPopulatedBins(res.generatorSignal,numberOfBins);

    binResp = zeros(size(binMean));
    respSTD = zeros(size(binMean));
    for bb = 1:length(binMean)
       binResp(bb) = mean(res.measuredResponse(binID == bb));
       respSTD(bb) = std(res.measuredResponse(binID == bb));
    end
    binErr = binSTD ./ sqrt(n);
    respErr = respSTD ./ sqrt(n);
    
    res.nonlinearity.binMean = binMean;
    res.nonlinearity.binErr = binErr;
    res.nonlinearity.respMean = binResp;
    res.nonlinearity.respErr = respErr;

    % fit nonlinearity
    params0 = [0.005 20 max(binResp) 0];
    fitRes = fitCRF_sigmoid(binMean,binResp,params0);
    fitXX = min(binMean - binErr): max(binMean + binErr);
    fitYY = sigmoidCRF(fitXX,fitRes.k, fitRes.c0, fitRes.amp, fitRes.yOff);
    res.nonlinearity.fitXX = fitXX;
    res.nonlinearity.fitYY = fitYY;
    res.nonlinearity.fitParams = fitRes;

end