function TreeToHdf5(tree,fileName)

    for nn = 1:tree.descendentsDepthFirst.length
        currentNode = tree.descendentsDepthFirst(nn);
        if currentNode.isLeaf
            splitPath = ['/',currentNode.splitValue];
            parent = currentNode.parent;
            while ~isempty(parent.parent)
                newSplitValue = parent.splitValue;
                newSplitKey = parent.parent.splitKey;
                if isnumeric(newSplitValue)
                    newSplitValue = num2str(newSplitValue);
                end
                parent = parent.parent;
                
                if isempty(newSplitValue)
                    continue
                end
                newSplitValue = replace(newSplitValue,'\','_');
                newSplitValue = [char(newSplitKey),'=',newSplitValue];
                splitPath = ['/',newSplitValue,splitPath];
            end
            for ee = 1:currentNode.epochList.length
                response = riekesuite.getResponseVector(currentNode.epochList.elements(ee),'Amp1');
                frame_monitor = riekesuite.getResponseVector(currentNode.epochList.elements(ee),'Frame Monitor');

                h5create([fileName,'.h5'],[splitPath,'/epoch',num2str(ee),'/response'],size(response))
                h5write([fileName,'.h5'], [splitPath,'/epoch',num2str(ee),'/response'], response)
                h5create([fileName,'.h5'],[splitPath,'/epoch',num2str(ee),'/frame_monitor'], size(frame_monitor))
                h5write([fileName,'.h5'], [splitPath,'/epoch',num2str(ee),'/frame_monitor'], frame_monitor)
                
                protocol_settings = currentNode.epochList.elements(ee).get('protocolSettings');
                keyList = split(string(protocol_settings.keySet),',');
                for kk = 1:length(keyList)
                    newKey = replace(keyList(kk),'[','');
                    newKey = replace(newKey,']','');
                    newKey = strtrim(newKey);

                    newVal = protocol_settings.get(newKey);
                    if size(newVal) > 1
                        newVal = convertJavaArrayList(newVal);
                    end
                    if isa(newVal,'java.util.Date')
                        newVal = char(newVal.toString);
                    end

    %                 try
                        h5writeatt([fileName,'.h5'],splitPath,char(newKey),newVal)
    %                 catch
    %                     2; 
    %                 end
                end
            end
%             responseMatrix = riekesuite.getResponseMatrix(currentNode.epochList,'Amp1');
%             frameMonitor = riekesuite.getResponseMatrix(currentNode.epochList,'Frame Monitor');
% 
%             h5create([fileName,'.h5'],[splitPath,'/','response/'],size(responseMatrix))
%             h5write([fileName,'.h5'], [splitPath,'/','response/'], responseMatrix)
% 
%             h5create([fileName,'.h5'], [splitPath,'/','FrameMonitor/'], size(frameMonitor))
%             h5write([fileName,'.h5'], [splitPath,'/','FrameMonitor/'], frameMonitor)
            
%             ProtocolSettings = currentNode.epochList.firstValue.get('ProtocolSettings');
%             keyList = split(string(ProtocolSettings.keySet),',');
%             for kk = 1:length(keyList)
%                 newKey = replace(keyList(kk),'[','');
%                 newKey = replace(newKey,']','');
%                 newKey = strtrim(newKey);
% 
%                 newVal = ProtocolSettings.get(newKey);
%                 if size(newVal) > 1
%                     newVal = convertJavaArrayList(newVal);
%                 end
%                 if isa(newVal,'java.util.Date')
%                     newVal = char(newVal.toString);
%                 end
%                 
% %                 try
%                     h5writeatt([fileName,'.h5'],splitPath,char(newKey),newVal)
% %                 catch
% %                     2; 
% %                 end
%             end

        else


        end
    end
end

