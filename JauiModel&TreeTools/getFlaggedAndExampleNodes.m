function getFlaggedAndExampleNodes(node, saveFileDirectory, saveFileID)
    ip = inputParser;
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    ip.addRequired('saveFileDirectory',@ischar);
    ip.addRequired('saveFileID',@ischar);
    ip.parse(node,saveFileDirectory,saveFileID);
    node = ip.Results.node;
    saveFileDirectory = ip.Results.saveFileDirectory;
    saveFileID = ip.Results.saveFileID;
    
    select = {}; ctS = 0;
    example = {}; ctE = 0;
    for nn = 1:node.descendentsDepthFirst.length
        if node.descendentsDepthFirst(nn).custom.get('isSelected')
            ctS = ctS + 1;
            splitValues = node.descendentsDepthFirst(nn).splitValues;
            javaObj = splitValues.values.toArray;
            select{ctS} = javaObj;
        end
        if node.descendentsDepthFirst(nn).custom.get('isExample')
            ctE = ctE + 1;
            splitValues = node.descendentsDepthFirst(nn).splitValues;
            javaObj = splitValues.values.toArray;
            example{ctE} = javaObj;
        end
    end

    save([saveFileDirectory, saveFileID],'select','example');
end