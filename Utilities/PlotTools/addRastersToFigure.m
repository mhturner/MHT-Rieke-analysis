function addRastersToFigure(spikeBinary,figID)

    for tt = 1:size(spikeBinary,1) %for trials
        spTimes = find(spikeBinary(tt,:));
        if isempty(spTimes)
        yUp = []; yDown = [];
        else
        yUp = (tt - 0.2) .* ones(size(spTimes)); yDown = (tt - 0.8) .* ones(size(spTimes));
        end
        addLineToAxis(spTimes, yUp,['top',num2str(tt)],figID,'k','none','.')
        addLineToAxis(spTimes, yDown,['bottom',num2str(tt)],figID,'k','none','none')
    end

end