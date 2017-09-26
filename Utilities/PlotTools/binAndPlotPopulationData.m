function binAndPlotPopulationData(allX, allY, binning, figureHandle, plotColor)
    % binAndPlotPopulationData(allX, allY, binning, figureHandle, plotColor)
    % Binning is either a) number of bins or b) defined bin edges
    
    if (nargin < 5)
        plotColor = 'k';
    end
if length(binning) > 1
    binEdges = binning;
    noBins = length(binEdges) - 1;
else
    noBins = binning;
    binEdges = linspace(min(allX),max(allX),noBins + 1);
end

XX.mean = []; XX.err = [];
YY.mean = []; YY.err = [];
for bb = 1:noBins
    inds = find(allX >= binEdges(bb)  & allX < binEdges(bb + 1));
    if bb == 1
        addInds = find(allX <  binEdges(1));
        inds = union(inds,addInds);
    elseif bb == noBins
        addInds = find(allX >=  binEdges(end));
        inds = union(inds,addInds);
    end
    currentXvals = allX(inds);
    currentYvals = allY(inds);

    XX.mean(bb) = mean(currentXvals); XX.err(bb) = std(currentXvals) ./ sqrt(length(inds));
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