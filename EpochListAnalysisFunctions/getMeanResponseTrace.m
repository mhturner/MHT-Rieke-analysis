function response = getMeanResponseTrace(epochList,recordingType)
    % USAGE: trace = getMeanResponseTrace(epochList,recordingType)
    % -epochList is a riekesuite epoch list
    % -recordingType is: 'extracellular' (default) - PSTH
    %                   'iClamp, spikes' - PSTH
    %                   'iClamp, subthreshold' - sub-threshold Vm
    %                           (spikes filtered out)
    %                   'iClamp' - Vm (mV), typically analog cells
    %                   'exc' or 'inh' - current (pA)
    %                   'exc, conductance' or 'inh, conductance' -
    %                           estimated conductance (DF  = 60 mV) 
    % MHT 4/18/16
    ip = inputParser;
    ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
    ip.addRequired('recordingType',@ischar);
    ip.parse(epochList,recordingType);
    epochList = ip.Results.epochList;
    recordingType = ip.Results.recordingType;

    sampleRate = epochList.firstValue.protocolSettings('sampleRate'); %Hz
    baselineTime = epochList.firstValue.protocolSettings('preTime'); %msec
    baselinePoints = (baselineTime / 1e3) * sampleRate; %msec -> datapoints
    
    %for smoothed PSTH...
    filterSigma = (5 / 1e3) * sampleRate; %5 msec -> datapoints
    newFilt = gaussFilter1D(filterSigma);
    
    amp = epochList.firstValue.protocolSettings('amp');
    dataMatrix = riekesuite.getResponseMatrix(epochList,amp);
    response.n = size(dataMatrix,1);
    response.timeVector = (1:size(dataMatrix,2))./ sampleRate;
    if strcmp(recordingType, 'extracellular')
        checkDetectionFlag = 0; %will throw figures
        epochNo = 0; %for warnings display purposes
        specialFlag = []; %wonky spikes option
        SpikeStruct = SpikeDetector(dataMatrix,checkDetectionFlag,epochNo,specialFlag);
        spikeBinary = zeros(size(dataMatrix));
        if (response.n == 1) %single trial
            spikeBinary(SpikeStruct.sp) = 1;
            PSTH = sampleRate*conv(spikeBinary,newFilt.amp,'same');
        else %multiple trials
            PSTH = zeros(size(dataMatrix));
            for ss = 1:size(spikeBinary,1)
                SpikeStruct.sp{ss}(SpikeStruct.violation_ind{ss}) = []; %remove refractory violations
                spikeBinary(ss,SpikeStruct.sp{ss}) = 1;
                PSTH(ss,:) =  sampleRate*conv(spikeBinary(ss,:),newFilt.amp,'same');
            end
        end
        
        response.mean = mean(PSTH,1);
        response.stdev = std(PSTH,[],1);
        response.SEM = response.stdev ./ sqrt(response.n);
        response.units = 'Spikes/sec';

    elseif strcmp(recordingType,'iClamp, spikes')
        threshold = -20; %mV
        checkDetectionFlag = 0; %will throw figures
        searchInterval = 1.5; %msec, how long to look for repolarization?
        SpikeStruct = CurrentClampSpikeDetector(dataMatrix,threshold,checkDetectionFlag,(searchInterval / 1e3) * sampleRate);
        spikeBinary = zeros(size(dataMatrix));
        PSTH = zeros(size(dataMatrix));
        for ss = 1:size(spikeBinary,1)
            spikeBinary(ss,SpikeStruct.sp{ss}) = 1;
            PSTH(ss,:) =  sampleRate*conv(spikeBinary(ss,:),newFilt.amp,'same');
        end
        response.mean = mean(PSTH,1);
        response.stdev = std(PSTH,[],1);
        response.SEM = response.stdev ./ sqrt(response.n);
        response.units = 'Spikes/sec';
        
    elseif strcmp(recordingType,'iClamp, subthreshold')
        %median filter (width 5 msec) to remove spikes
        subThresholdMatrix = medfilt1(dataMatrix,(5 / 1e3) * sampleRate,[],2);
        response.mean = mean(subThresholdMatrix,1);
        response.stdev = std(subThresholdMatrix,[],1);
        response.SEM = response.stdev ./ sqrt(response.n);
        response.units = 'mV';
        response.baseline = mean(response.mean(1:baselinePoints));
        
    elseif strcmp(recordingType,'iClamp')
        response.mean = mean(dataMatrix,1);
        response.stdev = std(dataMatrix,[],1);
        response.SEM = response.stdev ./ sqrt(response.n);
        response.units = 'mV';
        response.baseline = mean(response.mean(1:baselinePoints));
        
    elseif or(~isempty(strfind(recordingType,'exc')),~isempty(strfind(recordingType,'inh')))
        baselines = mean(dataMatrix(:,1:baselinePoints),2); %baseline for each trial
        baselineSubtracted = dataMatrix - repmat(baselines,1,size(dataMatrix,2));
        if ~isempty(strfind(recordingType,'conductance')) %estimate conductance, nS
            if strcmp(recordingType,'exc')
                DF = -60; %mV
            elseif strcmp(recordingType,'inh')
                DF = 60; %mV
            end
            baselineSubtracted = baselineSubtracted ./ DF;
        end
        response.mean = mean(baselineSubtracted,1);
        response.stdev = std(baselineSubtracted,[],1);
        response.SEM = response.stdev ./ sqrt(response.n);
        response.units = 'pA';
    else
        response.mean = mean(dataMatrix,1);
        response.stdev = std(dataMatrix,[],1);
        response.SEM = response.stdev ./ sqrt(response.n);
        response.units = '?';
        warning('Unrecognized recording type, no processing done on traces')
    end
     
end