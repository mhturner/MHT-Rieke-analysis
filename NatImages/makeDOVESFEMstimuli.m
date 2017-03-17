%makeDOVESFEMstimuli
%011516
IMAGES_DIR            = '~/Documents/MATLAB/MHT-analysis/resources/Doves/Images/';
FIXATIONS_DIR = '~/Documents/MATLAB/MHT-analysis/resources/Doves/Fixations/';
temp_names                  = GetFilenames(IMAGES_DIR,'.iml');	
for file_num = 1:size(temp_names,1)
    temp                    = temp_names(file_num,:);
    temp                    = deblank(temp);
    img_filenames_list{file_num}  = temp;
end

img_filenames_list = sort(img_filenames_list);
              
%%
%Pulling images from Van Hateren database. DOVES images are cropped VH
%images. Larger VH gives more wiggle room for eye movements to not run out
%of image in the surround
IMAGES_DIR_VH = '~/Documents/MATLAB/MHT-analysis-package/resources/vanhateren_iml/';

imEnd = 30; %1-101
sEnd = 10; %1-29

pullData = [];
ct = 0;
FEMdata = struct;
for ii = 1:imEnd%101 %1-30
ImageIndex=ii;
for ss = 1:sEnd%29
SubjectIndex=ss;

%LCR is 1824 x 1140 at 1.3 um/pixel
LCRsize_um = [1824, 1140] .* 1.3; %microns, ([X Y])
%DOVES images are 3.3 um/pixel (198/60) on monkey retina
LCRsize_VHpix = LCRsize_um ./ 3.3; %DOVES image pixels
buffer = ceil(LCRsize_VHpix / 2); %DOVES image pixels, so frame doesn't run out of image ([X Y])

image_name = img_filenames_list{ii};

%Load  the image from VH database...
%DOVES image (1024 x 768) taken from center of VH image (1536 x 1024)
f1=fopen([IMAGES_DIR_VH, image_name],'rb','ieee-be');
w=1536;h=1024;
my_image=fread(f1,[w,h],'uint16');
my_image = my_image';

load ([FIXATIONS_DIR image_name '.mat']); %loads subj_names_list, fix_data, eye_data
[Y, X]=size(my_image);
eyeData = eye_data{SubjectIndex}; %sampled at 200 hz, each pixel is 1 ArcMin
%add offsets to eye trajectories to account for DOVES -> VH image
%256 in x, 128 in y. ([1536 1024] - [1024 768]) ./ 2
eyeX = eyeData(1,:) + 256; eyeY = eyeData(2,:) + 128;
fixationDurations = fix_data{ss}(3,:);

figure(1); clf;
imagesc(my_image);colormap gray; hold on;
axis equal
cutMe = 0;
if any(eyeX>(X-buffer(1))) %right
    plot([X-buffer(1) X-buffer(1)],[Y-buffer(2) 0+buffer(2)],'r--') %right
    cutMe = 1;
else
    plot([X-buffer(1) X-buffer(1)],[Y-buffer(2) 0+buffer(2)],'w--') %right
end
if any(eyeX<(0+buffer(1))) %left
    plot([0+buffer(1) 0+buffer(1)],[Y-buffer(2) 0+buffer(2)],'r--') %left
    cutMe = 1;
else
    plot([0+buffer(1) 0+buffer(1)],[Y-buffer(2) 0+buffer(2)],'w--') %left
end
if any(eyeY<(0+buffer(2))) %top
    plot([0+buffer(1) X-buffer(1)],[0+buffer(2) 0+buffer(2)],'r--') %top
    cutMe = 1;
else
    plot([0+buffer(1) X-buffer(1)],[0+buffer(2) 0+buffer(2)],'w--') %top
end
if any(eyeY>(Y-buffer(2))) %bottom
    plot([0+buffer(1) X-buffer(1)],[Y-buffer(2) Y-buffer(2)],'r--') %bottom
    cutMe = 1;
else
    plot([0+buffer(1) X-buffer(1)],[Y-buffer(2) Y-buffer(2)],'w--') %bottom
end



if (cutMe == 1)
    %exclude data
%     pause(0.01);
%     clf
else
    
    pullData = cat(1,pullData,[ii,ss]);

    
    instSpeed = sqrt(diff(eyeX.*3.3).^2 + diff(eyeY.*3.3).^2);
    saccadeStarts = getThresCross(instSpeed,50,1); %velocity threshold
    cutInd = find(diff(saccadeStarts)<10); % refractory period
    saccadeStarts(cutInd+1) = [];

    fixationStarts = [1 saccadeStarts + 10];
    fixationEnds = [saccadeStarts - 5 length(eyeX)];
    
%     figure(2); clf;
%     subplot(2,1,1)
%     plot(eyeX.*3.3,'b'); hold on; plot(eyeY.*3.3,'r');
%     plot([fixationStarts; fixationStarts],repmat([0; 5000],[1, length(fixationStarts)]),'g--')
%     ylabel('Pos (um)')
%     subplot(2,1,2)
%     plot(instSpeed,'k'); hold on
%     plot([saccadeStarts; saccadeStarts],repmat([0; 600],[1, length(saccadeStarts)]),'k--')
%     ylabel('Speed (um/sec)')

    %Criterion for inclusion: eye movements spanned at least 300 arcmin in
    %X and Y - s.t. there is some amt of exploration & large fixation changes
    if and(range(eyeX)>300,range(eyeY)>300)
        
        h1 = plot(eyeX, eyeY, 'Color', [0 1 0], 'LineWidth',1,'Marker','.');
        title(num2str(ss));
        drawnow
        
        %user entry to exclude bad traces (lost tracking)
        if ii==21
            A = input('Include: y/n ','s');
        else
            A = 'y';
        end
        if strcmp(A,'y')
            ct = ct + 1;
            FEMdata(ct).ImageIndex = ImageIndex;
            FEMdata(ct).SubjectIndex = SubjectIndex;
            FEMdata(ct).ImageName = image_name;
            FEMdata(ct).eyeX = eyeX; %VH pixels, 200 Hz
            FEMdata(ct).eyeY = eyeY; %VH pixels, 200 Hz
            FEMdata(ct).fixationStarts = fixationStarts; %sample points in eyeX, eyeY
            FEMdata(ct).fixationEnds = fixationEnds;
        else
            
        end

        
    else
        
    end
    
    
    
    figure(1); 

end
end
fclose(f1);
clc
disp(num2str(ii))
end

%% trim stims with saccades too close together - causes fixation end to be
% before start. 
load('dovesFEMstims_20160126.mat')
cutInds = [];
for ii = 1:length(FEMdata)
    if any(FEMdata(ii).fixationEnds - FEMdata(ii).fixationStarts < 0)
        cutInds = cat(2,cutInds,ii);
    end
    
end

%% Add frozen trajectories right to stim file
load('dovesFEMstims_20160422.mat')
for ii = 1:length(FEMdata)
    res = getDOVESFEMtrajectory(ii,'dovesFEMstims_20160422.mat');
    FEMdata(ii).frozenX = res.Frozen.xTraj;
    FEMdata(ii).frozenY = res.Frozen.yTraj;
%     figure(3); clf; hold on;
%     plot(FEMdata(ii).eyeX,'k'); plot(FEMdata(ii).eyeY,'k')
%     plot(FEMdata(ii).frozenX,'r'); plot(FEMdata(ii).frozenY,'r')
%     pause; clf;
end

save('dovesFEMstims_20160422.mat','FEMdata','imEnd','sEnd') 



%% copy necessary .iml image files to folder...
%this only up to image index30
save('dovesFEMstims_20160126.mat','FEMdata','imEnd','sEnd') 
fromFolder = IMAGES_DIR_VH;
toFolder = '~/Documents/MATLAB/turner-package/resources/VHsubsample_20160105/';

for ii = 1:length(FEMdata)
    image_name = img_filenames_list{FEMdata(ii).ImageIndex};
    
    copyfile([fromFolder,image_name],[toFolder, image_name]) 
    
end

