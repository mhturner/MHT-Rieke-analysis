function r = getRebounds(peaks_ind,trace,searchInterval)
%Mod MHT 1/28/15 - gets "rebounds" +/- searchInterval/2 of peaktime

peaks = trace(peaks_ind);
r.Left = zeros(size(peaks));
r.Right = zeros(size(peaks));

for i=1:length(peaks)
    startPoint = max(1,peaks_ind(i) - round(searchInterval/2));
    endPoint = min(peaks_ind(i)+round(searchInterval/2),length(trace));
    if peaks(i)<0 %negative peaks, look for positive rebounds
        rLeft = getPeaks(trace(startPoint:peaks_ind(i)),1);
        rRight = getPeaks(trace(peaks_ind(i):endPoint),1);
    elseif peaks(i)>0 %positive peaks, look for negative rebounds
        rLeft = getPeaks(trace(startPoint:peaks_ind(i)),-1);
        rRight = getPeaks(trace(peaks_ind(i):endPoint),-1);
    end 
    if isempty(rLeft); rLeft = 0; else rLeft = rLeft(1); end
    if isempty(rRight); rRight = 0; else rRight = rRight(1); end

    r.Left(i) = rLeft;
    r.Right(i) = rRight;

end

end