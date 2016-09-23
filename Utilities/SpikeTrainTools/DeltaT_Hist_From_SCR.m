function [Hist_XValues, Average_CumProb, FractionMatched]=DeltaT_Hist_From_SCR(STI,cost) 

%
% Calculates the distribution of DeltaT values from all valid pairwise
% comparisons of spike trains recorded from a single cell. Input is the
% cell array containing spike times and the chosen cost of shifting spikes in
% time.
%
% GJM   3/06
%

numbertrials=length(STI);

% number of spikes
NumSpikes = 0;
for trial = 1:numbertrials
    NumSpikes = NumSpikes + length(STI{trial});
end
NumSpikes = NumSpikes / numbertrials;

%
% compute the DeltaT values between paired spikes in each possible
% combination of spike trains
%


comparisoncount=1;                                                                        % number of spike train comparisons performed
for i=1:numbertrials-1;                                                                        % for all of the spike trains except the last...
    for j=i+1:numbertrials;                                                          % for the spike train number greater than j
        [d,scr]=spkd_with_scr(STI{i}, STI{j},cost);  
        % calculate the spike distance (and keep the scr matrix that enabled that calculation)
        
        [newDeltaT, newtli_spike, newtlj_spike]=Simple_DeltaT_From_SCR(scr,cost,STI{i},STI{j}); % get the DeltaT values from this pairing of spike trains (by decsontructing the SCR matrix)
        DeltaT{comparisoncount}=newDeltaT; tli_spike{comparisoncount} = newtli_spike; tlj_spike{comparisoncount} = newtlj_spike;
        comparisoncount=comparisoncount+1;
%         clear d
    end
end

%
% for each pairwise spike train comparison, compute the histogram of DeltaT values 
% and the corresponding cumulative probability distribution
%

MaxDeltaT=2./cost;     
Hist_XValues=(0:0.1:MaxDeltaT);
NumPairings = 0;
for a=1:comparisoncount-1;
    DeltaT_HistMatrix(a,:)=hist(DeltaT{a},Hist_XValues);
    NumPairings = NumPairings + max(cumsum(DeltaT_HistMatrix(a, :)));
    DeltaT_CumProbMatrix(a,:)=(cumsum(DeltaT_HistMatrix(a,:))./max(cumsum(DeltaT_HistMatrix(a,:))));
end
NumPairings = NumPairings / (comparisoncount-1);

%
% summarize the DeltaT values, both as a summed histogram of DeltaT values across all spike 
% train pairings, and as an average cumulative probability distribution
%

Summed_DeltaT_Hist=sum(DeltaT_HistMatrix,1);
Average_CumProb=sum(DeltaT_CumProbMatrix,1)./(comparisoncount-1);
FractionMatched = NumPairings / NumSpikes;
