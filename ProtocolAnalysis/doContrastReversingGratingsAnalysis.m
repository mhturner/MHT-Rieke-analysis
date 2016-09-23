function doContrastReversingGratingsAnalysis(node,varargin)
    ip = inputParser;
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    ip.addParameter('normalizePopulationF2',false,@islogical);
    ip.addParameter('noBins',false,@isnumeric);
    
    ip.parse(node,varargin{:});
    node = ip.Results.node;
    normalizePopulationF2 = ip.Results.normalizePopulationF2;
    noBins = ip.Results.noBins;

    centerNodes = {};
    surroundNodes = {};
    for nn = 1:node.descendentsDepthFirst.length
        if strcmp(node.descendentsDepthFirst(nn).splitKey,...
                'protocolSettings(currentBarWidth)') && node.descendentsDepthFirst(nn).custom.get('isSelected')
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
        
        figure; clf; %eg cell traces
        fig1=gca;
        set(fig1,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig1,'XLabel'),'String','Time (s)')

        figure; clf; %eg cell F2
        fig2=gca;
        set(fig2,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig2,'XLabel'),'String','Bar width (um)')

        figure; clf; %population F2
        fig3=gca;
        set(fig3,'XScale','linear','YScale','linear')
        set(0, 'DefaultAxesFontSize', 12)
        set(get(fig3,'XLabel'),'String','Bar width (um)')
        
        
        regionID = regionIDs(rr);
        allBarWidth = [];
        allF2 = [];
        for pp = 1:length(populationNodes)
            currentNode = populationNodes(pp);
            cellInfo = getCellInfoFromEpochList(currentNode.epochList);
            recType = getRecordingTypeFromEpochList(currentNode.epochList);

            barWidth = zeros(1,currentNode.children.length);
            F2.mean = zeros(1,currentNode.children.length);
            F2.sem = zeros(1,currentNode.children.length);
            colors = pmkmp(currentNode.children.length);
            for ee = 1:currentNode.children.length
                stats = getF1F2statistics(currentNode.children(ee).epochList,recType);
                F2.mean(ee) = stats.meanF2;
                F2.sem(ee) = stats.semF2;
                barWidth(ee) = currentNode.children(ee).splitValue;

                if currentNode.custom.get('isExample')
                    responseTrace = getCycleAverageResponse(currentNode.children(ee).epochList,recType);
                    addLineToAxis(responseTrace.timeVector,responseTrace.meanCycle,...
                        ['c',num2str(barWidth(ee))],fig1,colors(ee,:),'-','none')
                end
            end
            %example:
            if currentNode.custom.get('isExample')
                set(get(fig1,'YLabel'),'String',stats.units)
                addLineToAxis(0,0,cellInfo.cellID,fig1,'k','none','none')
                figID = ['CRGtrace_',regionID,cellInfo.cellType,'_',recType];
                makeAxisStruct(fig1,figID ,'RFSurroundFigs')

                set(get(fig2,'YLabel'),'String',stats.units)
                addLineToAxis(barWidth,F2.mean,...
                    'meanF2',fig2,'k','-','o')
                addLineToAxis(barWidth,F2.mean - F2.sem,...
                    'errDownF2',fig2,'k','--','none')
                addLineToAxis(barWidth,F2.mean + F2.sem,...
                    'errUpF2',fig2,'k','--','none')
                addLineToAxis(0,0,cellInfo.cellID,fig2,'k','none','none')
                figID = ['CRGF2_',regionID,cellInfo.cellType,'_',recType];
                makeAxisStruct(fig2,figID ,'RFSurroundFigs')
            end

            %population:
            if (normalizePopulationF2 == 1)
                F2.mean = F2.mean ./ max(F2.mean);
            end
            if currentNode.custom.get('isExample')
                addLineToAxis(barWidth,F2.mean,...
                    ['exampleF2_',num2str(pp)],fig3,[0.5 0.5 0.5],'-','none')
            end
            allBarWidth = cat(2,allBarWidth,barWidth);
            allF2 = cat(2,allF2,F2.mean);
        end

        [n,binMean,binSTD,binID] = histcounts_equallyPopulatedBins(allBarWidth,noBins);
        respMean = zeros(1,noBins);
        respErr = zeros(1,noBins);
        for bb = 1:noBins
            currentData = allF2(binID == bb);
            respMean(bb) = mean(currentData);
            respErr(bb) = std(currentData) ./ sqrt(n(bb));

            addLineToAxis([binMean(bb) binMean(bb)],...
               [respMean(bb) - respErr(bb), respMean(bb) + respErr(bb)],...
               ['popErrF2_',num2str(bb)],fig3,'k','-','none')

            addLineToAxis([binMean(bb) - binSTD(bb) ./sqrt(n(bb)) binMean(bb) + binSTD(bb) ./sqrt(n(bb))],...
               [respMean(bb), respMean(bb)],...
               ['popErrBin_',num2str(bb)],fig3,'k','-','none')
        end

        addLineToAxis(binMean,respMean,'popMean',fig3,'k','-','.')

        figID = ['CRGpopF2_',regionID,cellInfo.cellType,'_',recType];
        set(get(fig3,'YLabel'),'String',stats.units)
        makeAxisStruct(fig3,figID ,'RFSurroundFigs')
    end
end

