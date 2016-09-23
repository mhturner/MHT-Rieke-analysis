function doLinearEquivalentAnalysis(node,varargin)
    ip = inputParser;
    expectedMetrics = {'integrated','peak'};
    expectedStims = {'D','A'};
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    addParameter(ip,'metric','integrated',...
        @(x) any(validatestring(x,expectedMetrics)));
    addParameter(ip,'stimType','D',...
        @(x) any(validatestring(x,expectedStims)));
    
    ip.parse(node,varargin{:});
    node = ip.Results.node;
    
    metric = ip.Results.metric;
    stimType = ip.Results.stimType;

    figure; clf;
    fig1=gca;
    set(fig1,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig1,'XLabel'),'String','Time (s)')

    figure; clf;
    fig2=gca;
    set(fig2,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    
    figure; clf;
    fig3=gca;
    set(fig3,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig3,'XLabel'),'String','Subunit model')
    set(get(fig3,'YLabel'),'String','LN model')
    
    figure; clf;
    fig4=gca;
    set(fig4,'XScale','linear','YScale','linear')
    set(0, 'DefaultAxesFontSize', 12)
    set(get(fig4,'XLabel'),'String','Subunit model - LN model')
    set(get(fig4,'YLabel'),'String','Measured Image - disc')

    populationNodes = {};
    ct = 0;
    for nn = 1:node.descendentsDepthFirst.length
        if strcmp(node.descendentsDepthFirst(nn).splitKey,...
                'protocolSettings(imageName)') && node.descendentsDepthFirst(nn).custom.get('isSelected')
            ct = ct + 1;
            populationNodes(ct) = node.descendentsDepthFirst(nn); %#ok<AGROW>
        end
    end
    
    for pp = 1:length(populationNodes)
        currentNode = populationNodes{pp};
        cellInfo = getCellInfoFromEpochList(currentNode.epochList);
        recType = getRecordingTypeFromEpochList(currentNode.epochList);

        responseXY  = struct;
        meanTrace = struct;
        colors = pmkmp(currentNode.children.length + 1);
        for ii = 1:currentNode.children.length %loop over images
            responseXY(ii).imageResponse = [];
            responseXY(ii).intensityResponse = [];
            meanTrace(ii).imageTrace = 0;
            meanTrace(ii).intensityTrace = 0;
            
            ImageNode = currentNode.children(ii);
            ct = 0;
            patchLocations = [];
            for ee = 1:ImageNode.children.length %patches
                if ImageNode.children(ee).children.length == 2 %both image and intensity shown
                    ct = ct + 1;
                    stats_image = ...
                        getResponseAmplitudeStats(ImageNode.children(ee).childBySplitValue('image').epochList,recType);
                    stats_intensity = ...
                        getResponseAmplitudeStats(ImageNode.children(ee).childBySplitValue('intensity').epochList,recType);

                    response_image = ...
                        getMeanResponseTrace(ImageNode.children(ee).childBySplitValue('image').epochList,recType);
                    response_intensity = ...
                        getMeanResponseTrace(ImageNode.children(ee).childBySplitValue('intensity').epochList,recType);
                    
                    responseXY(ii).imageResponse = cat(2,responseXY(ii).imageResponse,stats_image.(metric).mean);
                    responseXY(ii).intensityResponse = cat(2,responseXY(ii).intensityResponse,stats_intensity.(metric).mean);
                    
                    meanTrace(ii).imageTrace = meanTrace(ii).imageTrace + response_image.mean;
                    meanTrace(ii).intensityTrace = meanTrace(ii).intensityTrace + response_intensity.mean;
                    
                    patchLocations(ct,:) = str2num(ImageNode.children(ee).splitValue); %#ok<AGROW,ST2NM>
                end
            end
            %get patches presented from this image:
            imageSize = [currentNode.parent.splitValue, currentNode.parent.splitValue];
            stimSet = currentNode.epochList.firstValue.protocolSettings.get('currentStimSet');
            imageSet = getNaturalImagePatchFromLocation(patchLocations,...
                ImageNode.splitValue,...
                'imageSize',imageSize,...
                'stimSet',stimSet);
            
            subunitSigma = 25; %microns
            centerSigma = 100; %microns
            contrastPolarity = -1;
            modelResponses = getSubunitModelResponse(imageSet.images,imageSet.backgroundIntensity,...
                'subunitSigma',subunitSigma,'centerSigma',centerSigma,...
                'contrastPolarity',contrastPolarity);
            modelDiff = modelResponses.SubunitModelResponse - modelResponses.LNmodelResponse;
            measuredDiff = responseXY(ii).imageResponse - responseXY(ii).intensityResponse;
            cc = corr(modelDiff',measuredDiff');
            disp(cc)
                
            if currentNode.custom.get('isExample')
                addLineToAxis(response_image.timeVector,meanTrace(ii).imageTrace ./ ct,...
                    ['im',num2str(ii)],fig1,colors(ii,:),'-','none')
                addLineToAxis(response_image.timeVector,meanTrace(ii).intensityTrace ./ ct,...
                    ['int',num2str(ii)],fig1,colors(ii,:),':','none')
                
                addLineToAxis(responseXY(ii).imageResponse,responseXY(ii).intensityResponse,...
                    ['allData',num2str(ii)],fig2,colors(ii,:),'none','o')
                
                addLineToAxis(modelResponses.SubunitModelResponse,modelResponses.LNmodelResponse,...
                    ['allModelResp',num2str(ii)],fig3,colors(ii,:),'none','o')
                
                addLineToAxis(modelDiff,measuredDiff,...
                    ['allCorr',num2str(ii)],fig4,colors(ii,:),'none','o')
            end
        end
        if currentNode.custom.get('isExample')
            set(get(fig1,'YLabel'),'String',stats_image.(metric).units)
            addLineToAxis(0,0,cellInfo.cellID,fig1,'k','none','none')
            figID = ['LE',stimType,'trace_',cellInfo.cellType,'_',recType];
            makeAxisStruct(fig1,figID ,'RFSurroundFigs')

            set(get(fig2,'XLabel'),'String',['Response to image (',num2str(stats_image.(metric).units),')'])
            set(get(fig2,'YLabel'),'String',['Response to intensity (',num2str(stats_image.(metric).units),')'])
            UpLim = max(struct2array(responseXY));
            DownLim = min(struct2array(responseXY));
            addLineToAxis([DownLim UpLim],[DownLim UpLim],'unity',fig2,'k','--','none')
            addLineToAxis(0,0,cellInfo.cellID,fig2,'k','none','none')
            figID = ['LE',stimType,'sum_',cellInfo.cellType,'_',recType];
            makeAxisStruct(fig2,figID ,'RFSurroundFigs')
            
            UpLim = max([modelResponses.SubunitModelResponse,modelResponses.LNmodelResponse]);
            DownLim = min([modelResponses.SubunitModelResponse,modelResponses.LNmodelResponse]);
            addLineToAxis([DownLim UpLim],[DownLim UpLim],'unity',fig3,'k','--','none')
            addLineToAxis(0,0,cellInfo.cellID,fig3,'k','none','none')
            figID = ['LE',stimType,'model_',cellInfo.cellType,'_',recType];
            makeAxisStruct(fig3,figID ,'RFSurroundFigs')
            
            addLineToAxis(0,0,cellInfo.cellID,fig4,'k','none','none')
            figID = ['LE',stimType,'corr_',cellInfo.cellType,'_',recType];
            makeAxisStruct(fig4,figID ,'RFSurroundFigs')
        end
        

    end
end

