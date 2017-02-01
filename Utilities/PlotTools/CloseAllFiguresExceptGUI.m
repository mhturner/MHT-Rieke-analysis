function CloseAllFiguresExceptGUI()
    figHandles = findall(0,'type','figure');
    keepInd = [];
    for f = 1:length(figHandles)
        if strcmp(figHandles(f).Name, 'Epoch Tree GUI')
            keepInd = f;
        end
    end
    figHandles(keepInd) = [];
    close(figHandles);
end