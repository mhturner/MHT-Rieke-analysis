function responseMatrix = getBaselineSubtractedResponseMatrix(epochList)
% res = getBaselineSubtractedResponseMatrix(epochList)
% MHT 8/30/2018
ip = inputParser;
ip.addRequired('epochList',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericEpochList'));
ip.parse(epochList);
epochList = ip.Results.epochList;

amp = epochList.firstValue.protocolSettings('amp');
sampleRate = epochList.firstValue.protocolSettings('sampleRate'); %Hz
baselineTime = epochList.firstValue.protocolSettings('preTime'); %msec
baselinePoints = (baselineTime / 1e3) * sampleRate; %msec -> datapoints

tempMat = riekesuite.getResponseMatrix(epochList,amp);
baselines = mean(tempMat(:,1:baselinePoints),2); %baseline for each trial
responseMatrix = tempMat - repmat(baselines,1,size(tempMat,2));
end