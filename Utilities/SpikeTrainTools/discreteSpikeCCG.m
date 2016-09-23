function res = discreteSpikeCCG(spikeTimes1, spikeTimes2, totalBinaryLength, window)
    % spikeTimes1,2 are generally big concatenated spike time arrays from
    %       many trials with buffers of size window between each trial
    % window = radius on each side of zero
    % totalBinaryLength = maximum value of big concatenated spike times,
    %       basically how long would a binary string need to be to
    %       represent all the spike times
    % MHT 7/29/13
    
    ACGhist1 = zeros(1,2*window+1);
    ACGhist2 = zeros(1,2*window+1);
    CCGhist = zeros(1,2*window+1);
    for i=1:length(spikeTimes1) %goes through each spike time
        referenceTime = spikeTimes1(i);
        if referenceTime > window && referenceTime < totalBinaryLength - window
            %CCG
            refereeTimeInds= abs(spikeTimes2-referenceTime)<window;
            refereeTimes=spikeTimes2(refereeTimeInds); %spike 2 times within window of current spike1 time
            refereeTimes=refereeTimes-referenceTime+window; %shift times to align with window
            CCGhist(refereeTimes)=CCGhist(refereeTimes)+1;
            %ACG1
            refereeTimeInds= abs(spikeTimes1-referenceTime)<window;
            refereeTimes=spikeTimes1(refereeTimeInds); %spike 1 times within window of current spike1 time
            refereeTimes=refereeTimes-referenceTime+window; %shift times to align with window
            ACGhist1(refereeTimes)=ACGhist1(refereeTimes)+1;
        end
    end
    
    for i=1:length(spikeTimes2) %goes through each spike time
        referenceTime = spikeTimes2(i);
        if referenceTime > window && referenceTime < totalBinaryLength - window
            %ACG2
            refereeTimeInds= abs(spikeTimes2-referenceTime)<window;
            refereeTimes=spikeTimes2(refereeTimeInds); %spike 2 times within window of current spike2 time
            refereeTimes=refereeTimes-referenceTime+window; %shift times to align with window
            ACGhist2(refereeTimes)=ACGhist2(refereeTimes)+1;
        end
    end

    %normalize CCG by geometric mean of autocorrelations
    res.CCG=CCGhist./sqrt(max(ACGhist1)*max(ACGhist2));
    res.ACG1=ACGhist1./max(ACGhist1);
    res.ACG2=ACGhist2./max(ACGhist2);
end