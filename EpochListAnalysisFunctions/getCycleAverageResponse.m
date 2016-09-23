function response = getCycleAverageResponse(epochList,recordingType)
    % USAGE: trace = getCycleAverageResponse(epochList,recordingType)
    % -epochList is a riekesuite epoch list
    % -recordingType is: 'extracellular' (default) - PSTH
    %                   'iClamp, spikes' - PSTH
    %                   'iClamp, subthreshold' - sub-threshold Vm
    %                           (spikes filtered out)
    %                   'iClamp' - Vm (mV), typically analog cells
    %                   'exc' or 'inh' - current, estimated conductance (DF  = 60 mV) 
    % MHT 5/13/16
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

    lcrFlag = epochList.firstValue.protocolSettings.keySet.contains('background:LightCrafter Stage@localhost:lightCrafterPatternRate');
    if (lcrFlag == 1)
        frameRate_calculated = epochList.firstValue.protocolSettings('background:LightCrafter Stage@localhost:lightCrafterPatternRate');
    else 
        frameRate_calculated = 60;
    end
    
    %timing stuff...
    baselinePoints = (baselineTime / 1e3) * sampleRate; %msec -> datapoints
    cycleLen = sampleRate/cycleFrequency;
    
    %for smoothed PSTH...
    filterSigma = (5 / 1e3) * sampleRate; %5 msec -> datapoints
    newFilt = gaussFilter1D(filterSigma);
    
    allCycles = [];
    for e = 1:epochList.length
        currentEpoch = epochList.elements(e);
        %load data
        amp = currentEpoch.protocolSettings.get('amp');
        currentData = (riekesuite.getResponseVector(currentEpoch,amp))';
        try
            FrameMonitor = riekesuite.getResponseVector(currentEpoch,'Frame Monitor');
        catch
            FrameMonitor = riekesuite.getResponseVector(currentEpoch,'Frame_Monitor');
        end
        %timing stuff
        preFrames = (currentEpoch.protocolSettings.get('preTime') / 1000) * frameRate_calculated;
        [frameTimes, ~] = getFrameTiming(FrameMonitor,lcrFlag);
        stimStart = frameTimes(preFrames + 1); %first flip into stim frames
        
        if strcmp(recordingType,'extracellular')
            checkDetectionFlag = 0; %will throw figures
            specialFlag = []; %wonky spikes option
            SpikeStruct = SpikeDetector(currentData,checkDetectionFlag,e,specialFlag);
            spikeBinary = zeros(size(currentData));
            spikeBinary(SpikeStruct.sp) = 1;
            epochResponse = spikeBinary;
            response.units = 'Spikes/sec';
            
        elseif strcmp(recordingType, 'iClamp, spikes')
            threshold = -20; %mV
            checkDetectionFlag = 0; %will throw figures
            searchInterval = 1.5; %msec, how long to look for repolarization?
            SpikeStruct = CurrentClampSpikeDetector(currentData,threshold,checkDetectionFlag,(searchInterval / 1e3) * sampleRate);
            spikeBinary = zeros(size(currentData));
            spikeBinary(SpikeStruct.sp) = 1;
            epochResponse = spikeBinary;
            response.units = 'Spikes/sec';
            
        elseif strcmp(recordingType,'iClamp, subthreshold')
            %median filter (width 5 msec) to remove spikes
            epochResponse = medfilt1(currentData,(5 / 1e3) * sampleRate,[],2);
            response.units = 'mV';

        elseif strcmp(recordingType,'iClamp')
            epochResponse = currentData - mean(currentData(1:baselinePoints));
            response.units = 'mV';
            
        elseif or(strcmp(recordingType,'exc'),strcmp(recordingType,'inh'))
            epochResponse = currentData - mean(currentData(1:baselinePoints));
            response.units = 'pA';
            
        else
            epochResponse = currentData;
            response.units = '?';
            warning('Unrecognized recording type, no processing done on traces')
        end
        
        
        noCycles = (epochList.firstValue.protocolSettings('stimTime')/1000)*cycleFrequency;
        cycles = zeros(noCycles,cycleLen);
        for cc = 1:noCycles
            cycles(cc,:) = epochResponse((stimStart + (cc-1)*cycleLen) : (stimStart + cc*cycleLen - 1));
        end
        allCycles = cat(1,allCycles,cycles);
    end
    if or(strcmp(recordingType,'extracellular'),strcmp(recordingType, 'Current Clamp'))
        for cc = 1:size(allCycles,1) %smoothed spike PSTH from spike binary
            allCycles(cc,:) = sampleRate*conv(allCycles(cc,:),newFilt.amp,'same'); %#ok<AGROW>
        end
    end
        response.timeVector = (1:cycleLen) ./ sampleRate;
        response.allCycles = allCycles;
        response.meanCycle = mean(allCycles,1);
        response.stdCycle = std(allCycles,[],1);
        response.semCycle = response.stdCycle ./ sqrt(size(allCycles,1));
end