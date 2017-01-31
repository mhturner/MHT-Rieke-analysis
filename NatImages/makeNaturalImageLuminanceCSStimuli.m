%20170127 - gets center & surround mean intensity from natural images. No
%measured eye movements. Just spits out values for c and s across a bunch
%of random locations. Protocol will cycle through these values at some
%parameterized switching period

%Init VH image data:
clear all; clc;
tic;
load('NaturalImageFlashLibrary_101716.mat')
imageNames = fieldnames(imageData);
resourcesDir = '~/Documents/MATLAB/turner-package/resources';

%Parameters:
centerDiameter_micron = 200; %microns
surroundDiameter_micron = 600; %centerDiameter to surroundDiameter annulus
MicronsPerPixel = 6.6;
patchesPerImage = 1e3;
rng(1); %set seed
ImageX = 1536; ImageY = 1024;

%Convert to pixels and create sampling masks
centerDiameter = round(centerDiameter_micron ./ MicronsPerPixel);
surroundDiameter = round(surroundDiameter_micron ./ MicronsPerPixel);
windowSize = surroundDiameter_micron; %microns, square window
windowSize_VHpix = round(windowSize ./ MicronsPerPixel); %DOVES image pixels
buffer = ceil(windowSize_VHpix / 2); %DOVES image pixels, so frame doesn't run out of image ([X Y])

[rr, cc] = meshgrid(1:windowSize_VHpix,1:windowSize_VHpix);
centerBinary = sqrt((rr-windowSize_VHpix/2).^2+(cc-windowSize_VHpix/2).^2) <= centerDiameter/2;

surroundBinary = sqrt((rr-windowSize_VHpix/2).^2+(cc-windowSize_VHpix/2).^2) <= surroundDiameter/2 &...
    sqrt((rr-windowSize_VHpix/2).^2+(cc-windowSize_VHpix/2).^2) > centerDiameter/2;

for imageIndex = 1:length(imageNames)
    ImageID = imageNames{imageIndex};
    fileId=fopen([resourcesDir, '/VHsubsample_20160105', '/', ImageID,'.iml'],'rb','ieee-be');
    img = fread(fileId, [1536,1024], 'uint16');
    ImageMin = min(img(:));
    ImageMax = max(img(:));
    ImageMean = mean(img(:));

    PatchLocation = nan(patchesPerImage,2);
    CenterIntensity = nan(1,patchesPerImage);
    SurroundIntensity = nan(1,patchesPerImage);
    for pp = 1:patchesPerImage
        % choose location randomly
        x = round(windowSize_VHpix/2 + (ImageX - windowSize_VHpix)*rand);
        y = round(windowSize_VHpix/2 + (ImageY - windowSize_VHpix)*rand);
        PatchLocation(pp,:) = [x, y];
        newFrame = ...
                    img(round(x-windowSize_VHpix/2 + 1):round(x+windowSize_VHpix/2),...
                    round(y-windowSize_VHpix/2 + 1):round(y+windowSize_VHpix/2));
        CenterIntensity(pp) = sum(sum(newFrame.*centerBinary)) ./ sum(centerBinary(:));
        SurroundIntensity(pp) = sum(sum(newFrame.*surroundBinary)) ./ sum(surroundBinary(:));
    end

    luminanceData(imageIndex).ImageIndex = imageIndex;
    luminanceData(imageIndex).ImageName = ImageID;
    luminanceData(imageIndex).ImageMin = ImageMin;
    luminanceData(imageIndex).ImageMax = ImageMax;
    luminanceData(imageIndex).ImageMean = ImageMean;
    luminanceData(imageIndex).PatchLocation = PatchLocation;
    luminanceData(imageIndex).CenterIntensity = CenterIntensity;
    luminanceData(imageIndex).SurroundIntensity = SurroundIntensity;
end

toc
currentDateString = char(datetime(date,'Format','yyyyMMdd'));
save(['VanHaterenCSLuminances_',currentDateString,'.mat'],'luminanceData')