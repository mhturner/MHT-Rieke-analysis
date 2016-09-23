function [n,binMean,binSTD,binID] = histcounts_equallyPopulatedBins(inputX,numberOfBins)
    [sortedValues, sortedInd] = sort(inputX);
    nPerBin = round(numel(inputX) / numberOfBins);
    n = zeros(1,numberOfBins);
    binMean = zeros(1,numberOfBins);
    binSTD = zeros(1,numberOfBins);
    binID = nan(size(inputX));
    for bb = 1:numberOfBins
        startPoint = (bb-1)*nPerBin + 1;
        endPoint = min(bb*nPerBin,length(sortedValues));
        if bb == numberOfBins
            endPoint = length(sortedValues); 
        end
        
        currentPopulation = sortedValues(startPoint:endPoint);
        
        n(bb) = length(currentPopulation);
        binMean(bb) = mean(currentPopulation);
        binSTD(bb) = std(currentPopulation);
        binID(sortedInd(startPoint:endPoint)) = bb;
    end

end