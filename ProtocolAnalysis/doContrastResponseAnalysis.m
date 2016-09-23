function doContrastResponseAnalysis(node,varargin)
    saveDirectory = '~/Documents/MATLAB/Analysis/Projects/RFSurround/';
    
    ip = inputParser;
    expectedMetrics = {'integrated','peak'};
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    addParameter(ip,'metric','integrated',...
        @(x) any(validatestring(x,expectedMetrics)));
    addParameter(ip,'contrastPolarity',1,@isnumeric);
    ip.parse(node,varargin{:});
    node = ip.Results.node;
    metric = ip.Results.metric;
    contrastPolarity = ip.Results.contrastPolarity;
    
    figure; clf;
    fig1=gca;
    set(fig1,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig1,'XLabel'),'String','Time (s)')
    
    figure; clf;
    fig2=gca;
    set(fig2,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig2,'XLabel'),'String','Contrast')
    
    populationNodes = {};
    ct = 0;
    for nn = 1:node.descendentsDepthFirst.length
        if strcmp(node.descendentsDepthFirst(nn).splitKey,...
                'protocolSettings(currentSpotContrast)') && node.descendentsDepthFirst(nn).custom.get('isSelected')
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
        contrasts = nan(1,currentNode.children.length);
        colors = pmkmp(currentNode.children.length);
        for ee = 1:currentNode.children.length
            stats = getResponseAmplitudeStats(currentNode.children(ee).epochList,recType);
            respAmps(ee) = stats.(metric).mean;
            contrasts(ee) = currentNode.children(ee).splitValue;
            
            if currentNode.custom.get('isExample')
                responseTrace = getMeanResponseTrace(currentNode.children(ee).epochList,recType);
                addLineToAxis(responseTrace.timeVector,responseTrace.mean,...
                    ['cont',num2str(contrasts(ee))],fig1,colors(ee,:),'-','none')
            end
        end
        
        %fit cumulative gaussian CRF function:
        params0 = [max(respAmps), 0.3, -0.5, 0];
        fitRes = fitCRF_cumGauss(contrastPolarity .* contrasts,respAmps,params0);
        
        fitX = -1:0.01:1;
        fitY = CRFcumGauss(contrastPolarity .* fitX,...
            fitRes.alphaScale,fitRes.betaSens,fitRes.gammaXoff,fitRes.epsilonYoff);
        fitParams.alphaScale(pp) = fitRes.alphaScale; fitParams.betaSens(pp) = fitRes.betaSens;
        fitParams.gammaXoff(pp) = fitRes.gammaXoff; fitParams.epsilonYoff(pp) = fitRes.epsilonYoff;

        
        if currentNode.custom.get('isExample')
            set(get(fig2,'YLabel'),'String',stats.(metric).units)
            addLineToAxis(contrasts,respAmps,...
                'data',fig2,'k','none','o')
            addLineToAxis(fitX,fitY,...
                'fit',fig2,'k','-','none')

            set(get(fig1,'YLabel'),'String',stats.peak.units)
            addLineToAxis(0,0,cellInfo.cellID,fig1,'k','none','none')
            makeAxisStruct(fig1,['CRFtrace_',cellInfo.cellType,'_',recType] ,'RFSurroundFigs')
            
            addLineToAxis(0,0,cellInfo.cellID,fig2,'k','none','none')
            makeAxisStruct(fig2,['CRF_',cellInfo.cellType,'_',recType] ,'RFSurroundFigs')
            
            save([saveDirectory, 'horCRF.mat'],'fitRes');
    
        end
    end

    
end