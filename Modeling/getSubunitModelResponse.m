function res = getSubunitModelResponse(stimulusCell,imageMean,varargin)
    ip = inputParser;
    ip.addRequired('stimulusCell',@iscell);
    ip.addRequired('imageMean',@isnumeric);
    
    addParameter(ip,'contrastPolarity', 1, @(x) ismember(x,[-1, 1])); %+/- 1
    addParameter(ip,'subunitSigma', 12, @isnumeric); %microns
    addParameter(ip,'centerSigma', 40, @isnumeric); %microns
    addParameter(ip,'pixelScaleFactor', 3.3, @isnumeric); %microns per pixel of image in stimulusCell
    

    ip.parse(stimulusCell,imageMean,varargin{:});
    stimulusCell = ip.Results.stimulusCell;
    imageMean = ip.Results.imageMean;
    contrastPolarity = ip.Results.contrastPolarity;
    pixelScaleFactor = ip.Results.pixelScaleFactor;
    %convert from microns to pixels:
    subunitSigma = round(ip.Results.subunitSigma ./ pixelScaleFactor);
    centerSigma = round(ip.Results.centerSigma ./ pixelScaleFactor);
    
    FilterSize = size(stimulusCell{1},1);
              
    % subunit locations - square grid
    TempFilter = zeros(FilterSize, FilterSize);
    SubunitLocations = find(rem(1:FilterSize, 2*subunitSigma) == 0);
    for x = 1:length(SubunitLocations)
        TempFilter(SubunitLocations(x), SubunitLocations) = 1;
    end
    SubunitIndices = find(TempFilter > 0);

    % center & subunit filters
    for x = 1:FilterSize
        for y = 1:FilterSize
            SubunitFilter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (subunitSigma^2))); %#ok<AGROW>
            RFCenter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (centerSigma^2))); %#ok<AGROW>
        end
    end
    subunitWeightings = RFCenter(SubunitIndices);

    % normalize each component
    subunitWeightings = subunitWeightings / sum(subunitWeightings);
    SubunitFilter = SubunitFilter / sum(SubunitFilter(:));

    %get subunit and LN model response to each stimulus in stimulusCell
    RFoutput_ln = zeros(1,length(stimulusCell));
    RFoutput_subunit = zeros(1,length(stimulusCell));
    for patch = 1:length(stimulusCell)
        %convert to (Weber) contrast relative to mean
        CurrentPatch = contrastPolarity * (stimulusCell{patch} - imageMean)./imageMean;

        % convolve patch with subunit filter
        ImagePatch = conv2(CurrentPatch, SubunitFilter, 'same');

        % activation of each subunit
        subunitActivations = ImagePatch(SubunitIndices);

        % 1) Linear integration:
        RFoutput_ln(patch) = sum(subunitActivations .* subunitWeightings);
        
        % 2) Nonlinear subunits:
        subunitOutputs = subunitActivations;
        subunitOutputs(subunitOutputs<0) = 0; %rectify subunit outputs
        RFoutput_subunit(patch) = sum(subunitOutputs.* subunitWeightings);
    end
    % rectify LN output:
    RFoutput_ln(RFoutput_ln < 0) = 0;
    res.LNmodelResponse = RFoutput_ln;
    
    res.SubunitModelResponse = RFoutput_subunit;
end