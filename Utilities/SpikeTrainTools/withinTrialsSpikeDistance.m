function res=withinTrialsSpikeDistance(spikeTimes,q_cost)
    %spikeTimes is a cell array with spike times over n trials
    %uses Victor & Purpura's spkd_with_scr.m fxn
    if ~iscell(spikeTimes)==1
       error('Argument spikeTimes must be a cell array') 
    end
    
    allDistances=zeros(1,sum(1:length(spikeTimes)-1));
    count=0;
    for i=1:length(spikeTimes) %for trials
        referenceTrial=spikeTimes{i};
        testTrials=i+1:length(spikeTimes); %don't double count or count identity
        for j=1:length(testTrials)
            testTrial=spikeTimes{testTrials(j)};
            [d,scr]=spkd_with_scr(referenceTrial,testTrial,q_cost);
            count=count+1;
            allDistances(count)=d;
        end

    end
    res.distances = allDistances;
    res.mean=mean(allDistances);
    res.sem=sqrt(var(allDistances))./sqrt(count);

end