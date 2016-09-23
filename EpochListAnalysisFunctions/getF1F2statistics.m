function stats = getF1F2statistics(epochList,recordingType)
    % USAGE: trace = getF1F2statistics(epochList,recordingType)
    % -epochList is a riekesuite epoch list
    % -recordingType is: 'extracellular' (default) - PSTH
    %                   'iClamp, spikes' - PSTH
    %                   'iClamp, subthreshold' - sub-threshold Vm
    %                           (spikes filtered out)
    %                   'iClamp' - Vm (mV), typically analog cells
    %                   'exc' or 'inh' - current, estimated conductance (DF  = 60 mV) 
    % MHT 6/27/16
    ip = inputParser;
    ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
    ip.addRequired('recordingType',@ischar);
    ip.parse(epochList,recordingType);
    epochList = ip.Results.epochList;
    recordingType = ip.Results.recordingType;
    
    sampleRate = epochList.firstValue.protocolSettings('sampleRate'); %Hz
    baselineTime = epochList.firstValue.protocolSettings('preTime'); %msec
    cycleFrequency = [epochList.firstValue.protocolSettings('cycleFrequency'), ...
        epochList.firstValue.protocolSettings('temporalFreq'),...
        epochList.firstValue.protocolSettings('temporalFrequency')];
    if isempty(cycleFrequency)
       error('getCycleAverageResponse: no protocol parameter cycleFrequency or similar')
    end

    baselinePoints = (baselineTime / 1e3) * sampleRate; %msec -> datapoints

    F1s = [];
    F2s = [];
    for e = 1:epochList.length
        currentEpoch = epochList.elements(e);
        %load data
        amp = currentEpoch.protocolSettings.get('amp');
        currentData = (riekesuite.getResponseVector(currentEpoch,amp))';
        
        if strcmp(recordingType,'extracellular')
            checkDetectionFlag = 0; %will throw figures
            specialFlag = []; %wonky spikes option
            SpikeStruct = SpikeDetector(currentData,checkDetectionFlag,e,specialFlag);
            spikeBinary = zeros(size(currentData));
            spikeBinary(SpikeStruct.sp) = 1;
            epochResponse = spikeBinary;
        elseif strcmp(recordingType, 'iClamp, spikes')
            threshold = -20; %mV
            checkDetectionFlag = 0; %will throw figures
            searchInterval = 1.5; %msec, how long to look for repolarization?
            SpikeStruct = CurrentClampSpikeDetector(currentData,threshold,checkDetectionFlag,(searchInterval / 1e3) * sampleRate);
            spikeBinary = zeros(size(currentData));
            spikeBinary(SpikeStruct.sp) = 1;
            epochResponse = spikeBinary;
            
        elseif strcmp(recordingType,'iClamp, subthreshold')
            %median filter (width 5 msec) to remove spikes
            epochResponse = medfilt1(currentData,(5 / 1e3) * sampleRate,[],2);

        elseif strcmp(recordingType,'iClamp')
            epochResponse = currentData;
            stats.baseline = mean(currentData(1:baselinePoints));
            
        elseif or(strcmp(recordingType,'exc'),strcmp(recordingType,'inh'))
            epochResponse = currentData - mean(currentData(1:baselinePoints));
        else
            epochResponse = currentData;
            warning('Unrecognized recording type, no processing done on traces')
        end
        
        res = getF1F2Power(epochResponse,cycleFrequency,sampleRate,[]);
        if or(strcmp(recordingType,'iClamp, spikes'),strcmp(recordingType,'extracellular'))
            F1s(e) = res.F1amplitude .* sampleRate; %convert to spikes/sec
            F2s(e) = res.F2amplitude .* sampleRate;
        else
            F1s(e) = res.F1amplitude; %amplitude in input units (e.g. pA or mV)
            F2s(e) = res.F2amplitude;
        end
    end
        stats.n = length(F1s);
    
        stats.allF1s = F1s;
        stats.meanF1 = mean(F1s);
        stats.stdF1 = std(F1s);
        stats.semF1 = stats.stdF1 ./ sqrt(stats.n);
        
        stats.allF2s = F2s;
        stats.meanF2 = mean(F2s);
        stats.stdF2 = std(F2s);
        stats.semF2 = stats.stdF2 ./ sqrt(stats.n);
        
        if or(strcmp(recordingType,'iClamp, spikes'),strcmp(recordingType,'extracellular'))
            stats.units = 'Spikes/sec';
        elseif or(strcmp(recordingType,'exc'),strcmp(recordingType,'inh'))
            stats.units = 'pA';
        elseif or(strcmp(recordingType,'iClamp'),strcmp(recordingType,'iClamp, subthreshold'))
            stats.units = 'mV';
        else
            stats.units = '?';
        end
end