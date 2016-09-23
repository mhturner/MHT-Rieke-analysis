function doAreaSummationAnalysis(node,varargin)
    ip = inputParser;
    expectedMetrics = {'integrated','peak'};
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    addParameter(ip,'metric','integrated',...
        @(x) any(validatestring(x,expectedMetrics)));
    addParameter(ip,'amplitudeMultiplier',1,@isnumeric);
    ip.parse(node,varargin{:});
    node = ip.Results.node;
    metric = ip.Results.metric;
    amplitudeMultiplier = ip.Results.amplitudeMultiplier;    
    figure; clf;
    fig1=gca;
    set(fig1,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig1,'XLabel'),'String','Time (s)')
    
    figure; clf;
    fig2=gca;
    set(fig2,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig2,'XLabel'),'String','Spot Diameter (um)')
    
    populationNodes = {};
    ct = 0;
    for nn = 1:node.descendentsDepthFirst.length
        if strcmp(node.descendentsDepthFirst(nn).splitKey,...
                'protocolSettings(currentSpotSize)') && node.descendentsDepthFirst(nn).custom.get('isSelected')
            ct = ct + 1;
            populationNodes(ct) = node.descendentsDepthFirst(nn); %#ok<AGROW>
        end
    end
    
    fitParams = struct;
    for pp = 1:length(populationNodes)
        currentNode = populationNodes{pp};
        cellInfo = getCellInfoFromEpochList(currentNode.epochList);
        recType = getRecordingTypeFromEpochList(currentNode.epochList);
        respAmps = nan(1,currentNode.children.length);
        spotSizes = nan(1,currentNode.children.length);
        colors = pmkmp(currentNode.children.length);
        for ee = 1:currentNode.children.length
            stats = getResponseAmplitudeStats(currentNode.children(ee).epochList,recType);
            respAmps(ee) = amplitudeMultiplier * stats.(metric).mean;
            spotSizes(ee) = currentNode.children(ee).splitValue;
            
            if currentNode.custom.get('isExample')
                responseTrace = getMeanResponseTrace(currentNode.children(ee).epochList,recType);
                addLineToAxis(responseTrace.timeVector,responseTrace.mean,...
                    ['spot',num2str(spotSizes(ee))],fig1,colors(ee,:),'-','none')
            end
        end
        
        %fit linear RF area-summation models:
        if ~isempty(strfind(cellInfo.cellType,'parasol'))
            params0 = [max(respAmps), 40, max(respAmps), 150];
            [Kc,sigmaC,Ks,sigmaS] = fitDoGAreaSummation(spotSizes,respAmps,params0);
            fitX = 0:max(spotSizes);
            fitY = DoGAreaSummation([Kc,sigmaC,Ks,sigmaS], fitX);
            fitParams.Kc(pp) = Kc; fitParams.sigmaC(pp) = sigmaC;
            fitParams.Ks(pp) = Ks; fitParams.sigmaS(pp) = sigmaS;
        elseif ~isempty(strfind(cellInfo.cellType,'horizontal'))
            params0 = [max(respAmps), 40];
            [Kc,sigmaC] = fitGaussianRFAreaSummation(spotSizes,respAmps,params0);
            fitX = 0:max(spotSizes);
            fitY = GaussianRFAreaSummation([Kc,sigmaC], fitX);
            fitParams.Kc(pp) = Kc; fitParams.sigmaC(pp) = sigmaC;
        end
        
        if currentNode.custom.get('isExample')
            set(get(fig2,'YLabel'),'String',stats.(metric).units)
            addLineToAxis(spotSizes,respAmps,...
                'data',fig2,'k','none','o')
            addLineToAxis(fitX,fitY,...
                'fit',fig2,'k','-','none')

            set(get(fig1,'YLabel'),'String',stats.peak.units)
            addLineToAxis(0,0,cellInfo.cellID,fig1,'k','none','none')
            makeAxisStruct(fig1,['ES_',cellInfo.cellType,'_',recType] ,'RFSurroundFigs')
            
            addLineToAxis(0,0,cellInfo.cellID,fig2,'k','none','none')
            makeAxisStruct(fig2,['ESAS_',cellInfo.cellType,'_',recType] ,'RFSurroundFigs')
    
        end
    end

    
end