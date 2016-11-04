IMAGES_DIR            = '~/Documents/MATLAB/MHT-analysis-package/resources/vanhateren_iml/';
temp_names                  = GetFilenames(IMAGES_DIR,'.iml');	
for file_num = 1:size(temp_names,1)
    temp                    = temp_names(file_num,:);
    temp                    = deblank(temp);
    img_filenames_list{file_num}  = temp;
end

img_filenames_list = sort(img_filenames_list);

%%
figure(1); clf;
for ii = 1:length(img_filenames_list)
    imInd = randsample(1:length(img_filenames_list),1); 
    f1=fopen(img_filenames_list{imInd},'rb','ieee-be');
    w=1536;h=1024;
    buf=fread(f1,[w,h],'uint16');
    colormap(gray);
    imagesc(buf'); axis image; axis off;
    title(img_filenames_list{imInd})
    pause;
    clf;
    
end


%%


pullImages = sort({'00657', '03347', '02733', '03584', '01154',...
              '00405', '01829', '02999', '01151', '03758',...
              '02281', '02265', '01769', '03760', '03447',...
              '00152', '01192', '03093', '00377', '00459'});
          
fromFolder = IMAGES_DIR;
toFolder = '~/Documents/MATLAB/turner-package/resources/VHsubsample_20160105/';


for ii = 1:length(pullImages)
   copyfile([fromFolder, 'imk',pullImages{ii},'.iml'],[toFolder, 'imk',pullImages{ii},'.iml']) 
    
end