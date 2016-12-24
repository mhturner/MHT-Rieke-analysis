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

    res.n = epochList.length;
    allStimuli = [];
    allResponses = [];
    for e = 1:epochList.length
        currentEpoch = epochList.elements(e);
        % get epoch response and stimulus
        epochRes = getNoiseStimulusAndResponse(currentEpoch,recordingType,...
            'seedName',seedName,...
            'keepExcPolarity', true,...
            'downSampleAtNoiseRate', false);
        allStimuli(e,:) = epochRes.stimulus;
        allResponses(e,:) = epochRes.response;
    end
    filterLen = 500; %msec, length of linear filter to compute
    %fraction of noise update rate at which to cut off filter spectrum
    freqCutoffFraction = 0.75;
    
    LinearFilter = LinFilterFinder(allStimuli,allResponses, epochRes.sampleRate, freqCutoffFraction*epochRes.updateRate);
    filterPts = (filterLen/1000)*epochRes.sampleRate;
    
    tempResp = reshape(allResponses',1,numel(allResponses));
    tempStim = reshape(allStimuli',1,numel(allStimuli));
    linearPrediction = conv(tempStim,LinearFilter);
    linearPrediction = linearPrediction(1:length(tempStim));

    res.stimulus = tempStim;
    res.LinearFilter = LinearFilter(1:filterPts);
    res.filterTimeVector = (1:filterPts) ./ epochRes.sampleRate; %sec
    res.measuredResponse = tempResp;
    res.generatorSignal = linearPrediction;
    res.updateRate = epochRes.updateRate;
    res.sampleRate = epochRes.sampleRate;
    
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
%     params0=[max(binResp), 0.05, 0, 0]';
    
    params0=[3*max(binResp), 0.3, -2, -1]';
    
    fitRes = fitNormcdfNonlinearity(binMean,binResp,params0);
    fitXX = min(binMean - binErr): max(binMean + binErr);
    fitYY = normcdfNonlinearity(fitXX,...
        fitRes.alpha,fitRes.beta,fitRes.gamma,fitRes.epsilon);
    res.nonlinearity.fitXX = fitXX;
    res.nonlinearity.fitYY = fitYY;
    res.nonlinearity.fitParams = fitRes;

end