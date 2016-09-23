function res=ComputePairwiseSpikeDistances(spikeTimes1,spikeTimes2,q_cost)
% res=ComputePairwiseSpikeDistances(spikeTimes1,spikeTimes2,q_cost)
    %spikeTimes is a cell array with spike times over n trials
    %uses Victor & Purpura's spkd_with_scr.m fxn
    if ~iscell(spikeTimes1)==1 && ~iscell(spikeTimes2)==1
       error('Argument spikeTimes must be a cell array') 
    end
    
    allDistances=zeros(1,length(spikeTimes1)*length(spikeTimes2));
    count=0;
    for i=1:length(spikeTimes1) %for trials - set1
        referenceTrial=spikeTimes1{i};
        for j=1:length(spikeTimes2) %for trials - set2
            testTrial=spikeTimes2{j};
            [d,~]=spkd_with_scr(referenceTrial,testTrial,q_cost);
            count=count+1;
            allDistances(count)=d;
        end
    end
    res.distances = allDistances;
    res.mean = mean(allDistances);
    res.sem = sqrt(var(allDistances))./sqrt(count);
end