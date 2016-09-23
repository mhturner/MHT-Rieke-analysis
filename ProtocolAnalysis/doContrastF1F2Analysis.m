function doContrastF1F2Analysis(node,nodeSplitter,varargin)
    ip = inputParser;
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    ip.addRequired('nodeSplitter',@(x)isa(x,'edu.washington.rieke.symphony.generic.GenericSplitValueMap'));
    ip.addParameter('noBins',false,@isnumeric);
    
    ip.parse(node,nodeSplitter,varargin{:});
    node = ip.Results.node;
    nodeSplitter = ip.Results.nodeSplitter;
    noBins = ip.Results.noBins;
    
    centerNodes = {};
    surroundNodes = {};
    for nn = 1:node.descendentsDepthFirst.length
        if strcmp(node.descendentsDepthFirst(nn).splitKey,...
                nodeSplitter) && node.descendentsDepthFirst(nn).custom.get('isSelected')
            if node.descendentsDepthFirst(nn).parent.splitValue == 0 % no mask - center
                centerNodes = cat(2,centerNodes,node.descendentsDepthFirst(nn));
            elseif node.descendentsDepthFirst(nn).parent.splitValue > 0 %mask - surround
                surroundNodes = cat(2,surroundNodes,node.descendentsDepthFirst(nn));
            end
        end
    end
    regionIDs = 'cs';
    for rr = 1:2
        if rr == 1
            populationNodes = centerNodes;
        elseif rr == 2
            populationNodes = surroundNodes;
        end
        if isempty(populationNodes)
            continue
        end
    
        figure; clf; %eg F1 traces
        fig1=gca;
        set(fig1,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig1,'XLabel'),'String','Time (s)')

        figure; clf; %eg F2 traces
        fig2=gca;
        set(fig2,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig2,'XLabel'),'String','Time (s)')

        figure; clf; %eg F2:F1 versus contrast
        fig3=gca;
        set(fig3,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig3,'XLabel'),'String','Contrast')
        set(get(fig3,'YLabel'),'String','F2/F1')

        figure; clf; %population F2:F1 versus contrast
        fig4=gca;
        set(fig4,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig4,'XLabel'),'String','Contrast')
        set(get(fig4,'YLabel'),'String','F2/F1')

        regionID = regionIDs(rr);
        allContrast = [];
        allF1 = [];
        allF2 = [];
        for pp = 1:length(populationNodes) %over cells
            cellNode = populationNodes(pp);
            cellInfo = getCellInfoFromEpochList(cellNode.epochList);
            recType = getRecordingTypeFromEpochList(cellNode.epochList);
            %F1
            F1node = cellNode.childBySplitValue('F1');
            contrast = zeros(1,F1node.children.length);
            F1mean = zeros(1,F1node.children.length);
            colors = pmkmp(F1node.children.length);
            for cc = 1:F1node.children.length %over contrast
                stats = getF1F2statistics(F1node.children(cc).epochList,recType);
                contrast(cc) = F1node.children(cc).splitValue;
                F1mean(cc) = stats.meanF1;
                if cellNode.custom.get('isExample')
                    responseTrace = getCycleAverageResponse(F1node.children(cc).epochList,recType);
                    addLineToAxis(responseTrace.timeVector,responseTrace.meanCycle,...
                        ['c',num2str(contrast(cc))],fig1,colors(cc,:),'-','none')
                end
            end
            allContrast = cat(2,allContrast,contrast);
            allF1 = cat(2,allF1,F1mean);

            %F2
            F2node = cellNode.childBySplitValue('F2');
            contrast = zeros(1,F2node.children.length);
            F2mean = zeros(1,F2node.children.length);
            for cc = 1:F2node.children.length %over contrast
                stats = getF1F2statistics(F2node.children(cc).epochList,recType);
                contrast(cc) = F2node.children(cc).splitValue;
                F2mean(cc) = stats.meanF2;
                if cellNode.custom.get('isExample')
                    responseTrace = getCycleAverageResponse(F2node.children(cc).epochList,recType);
                    addLineToAxis(responseTrace.timeVector,responseTrace.meanCycle,...
                        ['c',num2str(contrast(cc))],fig2,colors(cc,:),'-','none')
                end
            end
            allF2 = cat(2,allF2,F2mean);

            %example:
            if cellNode.custom.get('isExample')
                set(get(fig1,'YLabel'),'String',stats.units)
                addLineToAxis(0,0,cellInfo.cellID,fig1,'k','none','none')
                figID = ['F1trace_',regionID,cellInfo.cellType,'_',recType];
                makeAxisStruct(fig1,figID ,'RFSurroundFigs')

                set(get(fig2,'YLabel'),'String',stats.units)
                addLineToAxis(0,0,cellInfo.cellID,fig2,'k','none','none')
                figID = ['F2trace_',regionID,cellInfo.cellType,'_',recType];
                makeAxisStruct(fig2,figID ,'RFSurroundFigs')

                addLineToAxis(contrast,F2mean ./ F1mean,...
                    'F2F1',fig3,'k','-','o')
                addLineToAxis(0,0,cellInfo.cellID,fig3,'k','none','none')
                figID = ['F2F1_',regionID,cellInfo.cellType,'_',recType];
                makeAxisStruct(fig3,figID ,'RFSurroundFigs')
            end
        end
        
        [n,binMean,binSTD,binID] = histcounts_equallyPopulatedBins(allContrast,noBins);
        allResp = allF2 ./ allF1;
        respMean = zeros(1,noBins);
        respErr = zeros(1,noBins);
        for bb = 1:noBins
            currentData = allResp(binID == bb);
            respMean(bb) = mean(currentData);
            respErr(bb) = std(currentData) ./ sqrt(n(bb));

            addLineToAxis([binMean(bb) binMean(bb)],...
               [respMean(bb) - respErr(bb), respMean(bb) + respErr(bb)],...
               ['popErrF2_',num2str(bb)],fig4,'k','-','none')

            addLineToAxis([binMean(bb) - binSTD(bb) ./sqrt(n(bb)) binMean(bb) + binSTD(bb) ./sqrt(n(bb))],...
               [respMean(bb), respMean(bb)],...
               ['popErrBin_',num2str(bb)],fig4,'k','-','none')
        end

        addLineToAxis(binMean,respMean,'popMean',fig4,'k','-','.')

        figID = ['F2F1pop_',regionID,cellInfo.cellType,'_',recType];
        makeAxisStruct(fig4,figID ,'RFSurroundFigs') 
    end
end

