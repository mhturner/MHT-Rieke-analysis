% Load the image
ResourcesDir = '~/Documents/MATLAB/MHT-analysis-package/resources/';
rgbImage = imread([ResourcesDir,'flowers-800.tif']);
my_image = double(rgb2gray(rgbImage)); %convert to grayscale

[ImageX, ImageY] = size(my_image);
originalImageMean = mean(my_image(:));

randSeed = 1;
noPatches = Inf; %10000; Inf for every pixel (heatmap)

% RF properties
FilterSize = 50;                % size of patch (one side, in pixels) 50
SubunitRadius = 2;              % radius of subunit
CenterRadius = 10;              % center radius 10 -> 192um 2std diameter
CellSpacing = 2*CenterRadius; %for grid instead of random cell locations
contrastPolarity = 1;

clear RFCenter RFSurround SubunitFilter SubunitSurroundFilter
% create RF component filters
% subunit locations - square grid
TempFilter = zeros(FilterSize, FilterSize);
SubunitLocations = find(rem([1:FilterSize], 2*SubunitRadius) == 0);
for x = 1:length(SubunitLocations)
    TempFilter(SubunitLocations(x), SubunitLocations) = 1;
end
SubunitIndices = find(TempFilter > 0);

% center and subunit filters
for x = 1:FilterSize
    for y = 1:FilterSize
        SubunitFilter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (SubunitRadius^2)));
        RFCenter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (CenterRadius^2)));
    end
end
subunitWeightings = RFCenter(SubunitIndices);

% normalize each component
subunitWeightings = subunitWeightings / sum(subunitWeightings);
SubunitFilter = SubunitFilter / sum(SubunitFilter(:));

rng(randSeed)

%Every pixel, for heatmap
XX = [FilterSize/2:ImageX-FilterSize/2];
YY = [FilterSize/2:ImageY-FilterSize/2];
[Y,X] = meshgrid(YY,XX);
XX = X(:); YY = Y(:);

LNCenterResponse = zeros(1,length(XX));
SubunitCenterResponse = zeros(1,length(XX));

for cloc = 1:length(XX)
    newX = XX(cloc); newY = YY(cloc);

    % pull image patch
    CurrentPatch = my_image(newX-FilterSize/2+1:newX+FilterSize/2,...
        newY-FilterSize/2+1:newY+FilterSize/2);
    %convert to contrast
    CurrentPatch = contrastPolarity.*(CurrentPatch - originalImageMean)./originalImageMean;
    
    ImagePatch = conv2(CurrentPatch, SubunitFilter, 'same');
    % activation of each subunit
    subunitActivations = ImagePatch(SubunitIndices);
    
    % Linear center:
    LinearResponse = sum(subunitActivations .* subunitWeightings);
    LNCenterResponse(cloc) = max(LinearResponse,0); %threshold summed input

    % Subunit center:
    subunitOutputs = subunitActivations;
    subunitOutputs(subunitOutputs<0) = 0; %threshold each subunit
    SubunitCenterResponse(cloc) = sum(subunitOutputs.* subunitWeightings);
end

diffs = (SubunitCenterResponse - LNCenterResponse); % % % % % % compute model output differences % % % % %

subunitImage = reshape(SubunitCenterResponse,size(my_image,1)-FilterSize+1,size(my_image,2)-FilterSize+1);
lnImage = reshape(LNCenterResponse,size(my_image,1)-FilterSize+1,size(my_image,2)-FilterSize+1);

figure(2); clf;
subplot(1,4,1);
imagesc(my_image); colormap(gray); axis image; 
subplot(1,4,2)
imagesc(lnImage); colormap(gray); axis image; colorbar
subplot(1,4,3)
imagesc(subunitImage); colormap(gray); axis image; colorbar
subplot(1,4,4)
imagesc(subunitImage-lnImage); colormap(gray); axis image; colorbar

trimImage = uint8(rgbImage);
trimImage = trimImage(FilterSize/2:ImageX-FilterSize/2,FilterSize/2:ImageY-FilterSize/2,:);
imwrite(trimImage,'flowersMap_OrigImage.tif');
imwrite(lnImage,'flowersMap_ln.tif');
imwrite(subunitImage,'flowersMap_subunit.tif');
imwrite(subunitImage-lnImage,'flowersMap_diff.tif');
