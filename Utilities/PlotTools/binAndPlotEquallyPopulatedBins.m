function binAndPlotEquallyPopulatedBins(allX, allY, numberOfBins, figureHandle, plotColor)
    % binAndPlotEquallyPopulatedBins(allX, allY, numberOfBins, figureHandle, plotColor)
    
    if (nargin < 5)
        plotColor = 'k';
    end
    
[n,binMean,binSTD,binID] = histcounts_equallyPopulatedBins(allX,numberOfBins);
    

XX.mean = []; XX.err = [];
YY.mean = []; YY.err = [];
for bb = 1:numberOfBins
    inds = find(binID == bb);
    currentYvals = allY(inds);

    XX.mean(bb) = binMean(bb); XX.err(bb) = binSTD(bb) ./ sqrt(n(bb));
    YY.mean(bb) = mean(currentYvals); YY.err(bb) = std(currentYvals) ./ sqrt(length(inds));
    
    addLineToAxis([XX.mean(bb) - XX.err(bb),  XX.mean(bb) + XX.err(bb)],...
        [YY.mean(bb), YY.mean(bb)],...
        ['errX',num2str(bb)],figureHandle,plotColor,'-','none')
    
    addLineToAxis([XX.mean(bb),  XX.mean(bb)],...
        [YY.mean(bb) - YY.err(bb), YY.mean(bb) + YY.err(bb)],...
        ['errY',num2str(bb)],figureHandle,plotColor,'-','none')
end

addLineToAxis(XX.mean,YY.mean,...
    'meanXY',figureHandle,plotColor,'-','o')
end