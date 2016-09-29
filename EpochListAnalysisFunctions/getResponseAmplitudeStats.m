function response = getResponseAmplitudeStats(epochList,recordingType)
    % USAGE: stats = getResponseAmplitudeStats(epochList,recordingType)
    % -epochList is a riekesuite epoch list
    % -recordingType is: 'extracellular' (default) - peak spike rate &
    %                           spike count
    %                   'iClamp, spikes' - peak spike rate & spike
    %                           count
    %                   'iClamp, subthreshold' - (spikes filtered out) peak voltage and
    %                           integrated voltage (mV*s)
    %                   'iClamp' - for analog cells. Peak voltage
    %                           and integrated voltage (mV*s)
    %                   'exc' or 'inh' - peak current & charge transfer
    %                           (pC)
    %                   'exc, conductance' or 'inh, conductance' - peak
    %                           conductance and integrated conductance (nS*s)
    % -spits out stats on peak response or integrated response (i.e. charge
    % transfer, in pC, for currents; mean spike rate for spike data;
    % MHT 6/3/16
    ip = inputParser;
    ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
    ip.addRequired('recordingType',@ischar);
    ip.parse(epochList,recordingType);
    epochList = ip.Results.epochList;
    recordingType = ip.Results.recordingType;

    sampleRate = epochList.firstValue.protocolSettings('sampleRate'); %Hz
    startTime = epochList.firstValue.protocolSettings('preTime'); %ms
    stopTime = epochList.firstValue.protocolSettings('preTime') + epochList.elements(1).protocolSettings.get('stimTime'); %ms
    startPoint = (startTime / 1e3) .* sampleRate;
    stopPoint = (stopTime / 1e3) .* sampleRate;
    
    %for smoothed PSTH...
    filterSigma = (5 / 1e3) * sampleRate; %5 msec -> datapoints
    newFilt = gaussFilter1D(filterSigma);
    
    amp = epochList.firstValue.protocolSettings('amp');
    dataMatrix = riekesuite.getResponseMatrix(epochList,amp);
    response.n = size(dataMatrix,1);
    if strcmp(recordingType, 'extracellular')
        [SpikeTimes, ~, ~] = ...
                SpikeDetector(currentData);
        spikeBinary = zeros(size(dataMatrix));
        if (response.n == 1) %single trial
            spikeBinary(SpikeTimes) = 1;
            PSTH = sampleRate*conv(spikeBinary,newFilt.amp,'same');
        else %multiple trials
            PSTH = zeros(size(dataMatrix));
            for ss = 1:size(spikeBinary,1)
                spikeBinary(ss,SpikeTimes{ss}) = 1;
                PSTH(ss,:) =  sampleRate*conv(spikeBinary(ss,:),newFilt.amp,'same');
            end
        end
        
        peaks = getPosNegPeaks(PSTH);
        response.peak.mean = mean(peaks,1);
        response.peak.stdev = std(peaks,[],1);
        response.peak.SEM = response.peak.stdev ./ sqrt(response.n);
        response.peak.units = 'Sp/s';
        if (response.n == 1) %single trial
            spikeCounts = spikeCounter(SpikeStruct.sp);
        else
            spikeCounts = cellfun(@spikeCounter,SpikeStruct.sp);
        end
        response.integrated.mean = mean(spikeCounts);
        response.integrated.stdev = std(spikeCounts);
        response.integrated.SEM = response.integrated.stdev ./ sqrt(response.n);
        response.integrated.units = 'Spikes';

    elseif strcmp(recordingType,'iClamp, spikes')
        [SpikeTimes, ~]...
                = CurrentClampSpikeDetector(currentData,'Threshold',-20);
        spikeBinary = zeros(size(dataMatrix));
        PSTH = zeros(size(dataMatrix));
        for ss = 1:size(spikeBinary,1)
            spikeBinary(ss,SpikeTimes{ss}) = 1;
            PSTH(ss,:) =  sampleRate*conv(spikeBinary(ss,:),newFilt.amp,'same');
        end
        peaks = getPosNegPeaks(PSTH);
        response.peak.mean = mean(peaks,1);
        response.peak.stdev = std(peaks,[],1);
        response.peak.SEM = response.peak.stdev ./ sqrt(response.n);
        response.peak.units = 'Sp/s';
        
        spikeCounts = cellfun(@spikeCounter,SpikeStruct.sp);
        response.integrated.mean = mean(spikeCounts);
        response.integrated.stdev = std(spikeCounts);
        response.integrated.SEM = response.integrated.stdev ./ sqrt(response.n);
        response.integrated.units = 'Spikes';
        
    elseif strcmp(recordingType,'iClamp, subthreshold')
        %median filter (width 5 msec) to remove spikes
        subThresholdMatrix = medfilt1(dataMatrix,(5 / 1e3) * sampleRate,[],2);
        baselines = mean(subThresholdMatrix(:,1:startPoint),2); %baseline for each trial
        subThresholdMatrix = subThresholdMatrix - repmat(baselines,1,size(subThresholdMatrix,2));
        
        peaks = getPosNegPeaks(subThresholdMatrix);
        response.peak.mean = mean(peaks,1);
        response.peak.stdev = std(peaks,[],1);
        response.peak.SEM = response.peak.stdev ./ sqrt(response.n);
        response.peak.units = 'mV';
        
        
        intVoltages = trapz(dataMatrix(:,startPoint:stopPoint),2) ./ sampleRate; %mV*s
        response.integrated.mean = mean(intVoltages);
        response.integrated.stdev = std(intVoltages);
        response.integrated.SEM = response.integrated.stdev ./ sqrt(response.n);
        response.integrated.units = 'mV*s';
        
    elseif strcmp(recordingType,'iClamp')
        baselines = mean(dataMatrix(:,1:startPoint),2); %baseline for each trial
        dataMatrix = dataMatrix - repmat(baselines,1,size(dataMatrix,2));
        
        peaks = getPosNegPeaks(dataMatrix);
        response.peak.mean = mean(peaks,1);
        response.peak.stdev = std(peaks,[],1);
        response.peak.SEM = response.peak.stdev ./ sqrt(response.n);
        response.peak.units = 'mV';
        
        intVoltages = trapz(dataMatrix(:,startPoint:stopPoint),2) ./ sampleRate; %mV*s
        response.integrated.mean = mean(intVoltages);
        response.integrated.stdev = std(intVoltages);
        response.integrated.SEM = response.integrated.stdev ./ sqrt(response.n);
        response.integrated.units = 'mV*s';
        
    elseif or(~isempty(strfind(recordingType,'exc')),~isempty(strfind(recordingType,'inh')))
        baselines = mean(dataMatrix(:,1:startPoint),2); %baseline for each trial
        baselineSubtracted = dataMatrix - repmat(baselines,1,size(dataMatrix,2));
        if ~isempty(strfind(recordingType,'conductance')) %estimate conductance, nS
            if strcmp(recordingType,'exc')
                DF = -60; %mV
            elseif strcmp(recordingType,'inh')
                DF = 60; %mV
            end
            baselineSubtracted = baselineSubtracted ./ DF; %nS
            
            peaks = getPosNegPeaks(baselineSubtracted);
            response.peak.mean = mean(peaks,1);
            response.peak.stdev = std(peaks,[],1);
            response.peak.SEM = response.peak.stdev ./ sqrt(response.n);
            response.peak.units = 'nS';

            intConductances = trapz(baselineSubtracted(:,startPoint:stopPoint),2) ./ sampleRate; %mV*s
            response.integrated.mean = mean(intConductances);
            response.integrated.stdev = std(intConductances);
            response.integrated.SEM = response.integrated.stdev ./ sqrt(response.n);
            response.integrated.units = 'nS*s';
        else %currents
            if strcmp(recordingType,'exc')
                polarity = -1; %inward
            elseif strcmp(recordingType,'inh')
                polarity = 1; %outward
            end
            baselineSubtracted = polarity * baselineSubtracted; %pA
            peaks = getPosNegPeaks(baselineSubtracted);
            response.peak.mean = mean(peaks,1);
            response.peak.stdev = std(peaks,[],1);
            response.peak.SEM = response.peak.stdev ./ sqrt(response.n);
            response.peak.units = 'pA';

            intCurrents = trapz(baselineSubtracted(:,startPoint:stopPoint),2) ./ sampleRate; %pA*s = pC
            response.integrated.mean = mean(intCurrents);
            response.integrated.stdev = std(intCurrents);
            response.integrated.SEM = response.integrated.stdev ./ sqrt(response.n);
            response.integrated.units = 'pC';
        end
    else
        error('Unrecognized recording type')
    end
    
    function count = spikeCounter(array)
        count = length(array(array > startPoint & array < stopPoint));
    end

    function peaks = getPosNegPeaks(matrix)
        [~, tempInd] = max(abs(matrix(:,startPoint:stopPoint)),[],2);
        peaks = nan(length(tempInd),1);
        for ii = 1:length(tempInd)
          peaks(ii) = matrix(ii,startPoint + tempInd(ii) - 1);
        end 
    end
     
end