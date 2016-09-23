function res = getPSTH(spikeTrials,binSize,binaryFlag)
% res = getPSTH(spikeTrials,binSize,binaryFlag)
    %spikeTrials is a n * d matrix of cell-attached spike recordings
    %    where d=number data points per trial and n is no trials
    %binsize (in data points) = 0 => use optimal bin size
    %   per Shimazaki & Shinomoto Neural Computation (2007)
    % binaryFlag = 1 for input that is a binary string of spike times
[n, d]=size(spikeTrials);

if binaryFlag %input is binary matrix of spike times
    pointSumSpikes=sum(spikeTrials);
    binarySpikes=spikeTrials;
else
    S=SpikeDetector(spikeTrials);
    binarySpikes=zeros(n,d);
    for i=1:length(S.sp)
        trialSpikes=S.sp{i};
        binarySpikes(i,trialSpikes)=1;
    end
    pointSumSpikes=sum(binarySpikes);
    
end

%optimize bin size. fminsearch gets stuck on these bumpy empirical cost
%functions. Dumb search works OK
%plotting the cost fxn is a nice way to see if there are too few trials to
%reliably get at the rate
%   e.g. very few trials might => minimum @ or near trial size
if binSize==0
    testDeltas=1:10000;
    costs=zeros(1,10000);
    for i=testDeltas
       costs(i)=binCost(testDeltas(i),pointSumSpikes,n);
    end
    binSize=find(costs==min(costs)); 
else
    
end
noBins=floor(d/binSize);
binCenters=binSize/2:binSize:noBins*binSize-binSize/2;
binSpikes=zeros(n,noBins);
for j=1:n %for trials
    for i=1:noBins %for bins
        binSpikes(j,i)=sum(binarySpikes(j,(i-1)*binSize+1:i*binSize));
    end
end
spikeSTD=std(binSpikes,[],1);
spikeSEM=spikeSTD./sqrt(n);

binSpikes=mean(binSpikes,1); %average over trials

res.binCenters = binCenters; %data points
res.spikeCounts = binSpikes; %mean per bin
res.spikeSEM = spikeSEM; %sem per bin
res.spikeSTD = spikeSTD;

end