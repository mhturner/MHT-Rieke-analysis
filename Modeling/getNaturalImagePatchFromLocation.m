function res = getNaturalImagePatchFromLocation(patchLocations,imageName,varargin)
    ip = inputParser;
    ip.addRequired('patchLocations',@ismatrix);
    ip.addRequired('imageName',@ismatrix);
    addParameter(ip,'imageSize',[200, 200],@ismatrix); %microns
    addParameter(ip,'stimSet','/VHsubsample_20160105',@ischar);

    ip.parse(patchLocations,imageName,varargin{:});
    
    patchLocations = ip.Results.patchLocations;
    imageName = ip.Results.imageName;
    imageSize = ip.Results.imageSize;
    stimSet = ip.Results.stimSet;

    %load appropriate image...
    resourcesDir = '~/Documents/MATLAB/turner-package/resources';
    fileId=fopen([resourcesDir, stimSet, '/imk', imageName,'.iml'],'rb','ieee-be');
    img = fread(fileId, [1536,1024], 'uint16');

    img = double(img);
    img = (img./max(img(:))); %rescale s.t. brightest point is maximum monitor level
    res.backgroundIntensity = mean(img(:));%set the mean to the mean over the image
    
    imageSize_VHpix = round(imageSize ./ (3.3)); %um / (um/pixel) -> pixel
    radX = round(imageSize_VHpix(1) / 2); %boundaries for fixation draws depend on stimulus size
    radY = round(imageSize_VHpix(2) / 2);
    images = cell(1,size(patchLocations,1));
    for ff = 1:size(patchLocations,1);
        images{ff} = img(round(patchLocations(ff,1)-radX):round(patchLocations(ff,1)+radX),...
            round(patchLocations(ff,2)-radY):round(patchLocations(ff,2)+radY));
    end
    res.images = images;
end