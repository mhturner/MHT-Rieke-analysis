%Pulls indices for peaks above some threshold
%good for spikelets or intracellular spikes
%just choose threshold high enough s.t. for each threshold crossing there's
%only one peak
%MHT 021614
function res=pullPeakTimes(trace,threshold,checkDetectionFlag,searchInterval)
    spikesUp=getThresCross(trace,threshold,1);
    inds = [];
    for ss = 1:length(spikesUp)
        searchEnd = min(length(trace),(spikesUp(ss)+searchInterval));
        searchTrace = trace((spikesUp(ss)+1):searchEnd);
        newDowns = getThresCross(searchTrace,threshold,-1);
        if isempty(newDowns)
            continue
        end
        
        spikeDown = spikesUp(ss)+newDowns(1);
        [val ind] = max(trace((spikesUp(ss)+1):spikeDown));
        inds = cat(2,inds,spikesUp(ss) + ind);
    end
    
    if checkDetectionFlag
        figure(10); clf;
        plot(trace,'k')
        hold on
        plot(inds,threshold.*ones(1,length(inds)),'rx')
        pause;
        
    end
    
    res=inds;
end