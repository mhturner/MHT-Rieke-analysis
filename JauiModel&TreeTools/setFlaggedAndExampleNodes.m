function setFlaggedAndExampleNodes(gui, tree, saveFileDirectory, saveFileID)
    ip = inputParser;
    ip.addRequired('tree',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    ip.addRequired('saveFileDirectory',@ischar);
    ip.addRequired('saveFileID',@ischar);
    ip.parse(tree,saveFileDirectory,saveFileID);
    tree = ip.Results.tree;
    saveFileDirectory = ip.Results.saveFileDirectory;
    saveFileID = ip.Results.saveFileID;
    
    load([saveFileDirectory, saveFileID],'select','example');
    
    for nn = 1:tree.descendentsDepthFirst.length
        splitValues = tree.descendentsDepthFirst(nn).splitValues;
        javaObj = splitValues.values.toArray;
        for ss = 1:length(select)
            if select{ss} == (javaObj)
                tree.descendentsDepthFirst(nn).custom.put('isSelected',true);
            end
        end
        for ee = 1:length(example)
            if example{ee} == (javaObj)
                tree.descendentsDepthFirst(nn).custom.put('isExample',true);
                tree.descendentsDepthFirst(nn).custom.get('display').put('backgroundColor','r');
            end
        end
    end
    gui.refreshBrowserNodes
end