function plotMultipleCategoryPointsAndStats(dataCell, categoryLabels, figureHandle, plotColor)
    if (nargin < 4)
        plotColor = 'k';
    end

    
    noCategories = length(dataCell);
    for cc = 1:noCategories
        currentLabel = categoryLabels{cc};
        currentData = dataCell{cc};
        x = cc * ones(size(currentData));
        addLineToAxis(x,currentData,[currentLabel, '_points'],figureHandle,plotColor,'none','o')
        addLineToAxis(cc,mean(currentData),[currentLabel, '_mean'],figureHandle,plotColor,'none','s')
        err = std(currentData) ./ sqrt(length(currentData));
        addLineToAxis([cc cc],[mean(currentData) + err, mean(currentData) - err],[currentLabel, '_err'],figureHandle,plotColor,'-','none')
        
    end
    xlim([0.5 cc+0.5])

end