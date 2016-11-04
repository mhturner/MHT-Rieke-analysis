%2016082616

IMAGES_DIR            = '~/Documents/MATLAB/MHT-analysis-package/resources/Doves/Images/';
FIXATIONS_DIR = '~/Documents/MATLAB/MHT-analysis-package/resources/Doves/Fixations/';
temp_names                  = GetFilenames(IMAGES_DIR,'.iml');	
for file_num = 1:size(temp_names,1)
    temp                    = temp_names(file_num,:);
    temp                    = deblank(temp);
    img_filenames_list{file_num}  = temp;
end

img_filenames_list = sort(img_filenames_list);
clc;
%%
tic
%Pulling images from Van Hateren database. DOVES images are cropped VH
%images. Larger VH gives more wiggle room for eye movements to not run out
%of image in the surround
IMAGES_DIR_VH = '~/Documents/MATLAB/MHT-analysis-package/resources/vanhateren_iml/';

centerDiameter_micron = 200; %microns
surroundDiameter_micron = 600; %centerDiameter to surroundDiameter annulus

centerDiameter = round(centerDiameter_micron ./ 3.3);
surroundDiameter = round(surroundDiameter_micron ./ 3.3);

%600 micron frame window
windowSize = [600, 600]; %microns, ([X Y])
%DOVES images are 3.3 um/pixel (198/60) on monkey retina
windowSize_VHpix = round(windowSize ./ 3.3); %DOVES image pixels
buffer = ceil(windowSize_VHpix / 2); %DOVES image pixels, so frame doesn't run out of image ([X Y])

[rr, cc] = meshgrid(1:windowSize_VHpix(1),1:windowSize_VHpix(2));
centerBinary = sqrt((rr-windowSize_VHpix(1)/2).^2+(cc-windowSize_VHpix(2)/2).^2) <= centerDiameter/2;

surroundBinary = sqrt((rr-windowSize_VHpix(1)/2).^2+(cc-windowSize_VHpix(2)/2).^2) <= surroundDiameter/2 &...
    sqrt((rr-windowSize_VHpix(1)/2).^2+(cc-windowSize_VHpix(2)/2).^2) > centerDiameter/2;

% figure(2); clf;
% subplot(211); imagesc(centerBinary);
% subplot(212); imagesc(surroundBinary);

ct = 0;
luminanceData = struct;
for ImageIndex = 1:101
    clc; disp(ImageIndex);
    image_name = img_filenames_list{ImageIndex};
    %Load  the image from VH database...
    %DOVES image (1024 x 768) taken from center of VH image (1536 x 1024)
    f1=fopen([IMAGES_DIR_VH, image_name],'rb','ieee-be');
    w=1536;h=1024;
    my_image=fread(f1,[w,h],'uint16');
    my_image = my_image';
    
    ImageMin = min(my_image(:));
    ImageMax = max(my_image(:));
    ImageMean = mean(my_image(:));

    load ([FIXATIONS_DIR image_name '.mat']); %loads subj_names_list, fix_data, eye_data
    [Y, X]=size(my_image);
    for SubjectIndex = 1:5 %        subjects 1-5
        eyeData = eye_data{SubjectIndex}; %sampled at 200 hz, each pixel is 1 ArcMin
        %add offsets to eye trajectories to account for DOVES -> VH image
        %256 in x, 128 in y. ([1536 1024] - [1024 768]) ./ 2
        eyeX = eyeData(1,:) + 256; eyeY = eyeData(2,:) + 128;
        
        % Look for lost tracking data in trajectories by computing
        % amplitude spectrum and looking for ~30 Hz signal in eyeX (tends to be
        % where lost tracking oscillations live)
        % Checked ~200 traces by eye, method below worked for all of them.
        % Seems to do a pretty good job.
        sf = 200; %sampling rate, Hz
        n = length(eyeX); %length of signal, datapoints
        if mod(n,2) == 1
           eyeX = eyeX(1:end-1);
           eyeY = eyeY(1:end-1);
           n = n - 1;
        end
        L = n / sf;
        tDim = (1:n)./sf;
        k = (1/L)*[0:(n/2-1) -n/2:-1]; %fourier domain, Hz
        fs = fftshift(k); %shifted to intuitive ordering
        specX = fftshift(fft(eyeX./n)); %eyeX signal scaled by length
        specY = fftshift(fft(eyeY./n)); %eyeY signal scaled by length
        %one-sided spectrum
        f = fs(n/2+1:end);
        ampX = 2.*abs(specX(n/2+1:end)); %amplitude spectrum, double b/c of symmetry about zero
        ampY = 2.*abs(specY(n/2+1:end));
        %smooth spectra
        f = smooth(f,10);
        ampX = smooth(ampX); ampY = smooth(ampY);
        [val, ind] = min(abs(f - 30)); %find 30 Hz signal)
        baselineInds = union(find(f>20 & f<25), find(f>35 & f<40));
        %look for 30 hz amplitude 2 stdev above nearby baseline
        baseline = mean(ampX(baselineInds)) + 2*std(ampX(baselineInds));
        if ampX(ind) > baseline;
           flag = 'x';
           continue
        else
            flag = '';
        end

%         figure(3); clf; xlabel('Freq (Hz)'); ylabel('Amp')
%         semilogy(f,ampX,'b');
%         hold on;
%         semilogy(f,ampY,'r');
%         semilogy(f(ind),ampX(ind),'kx')
%         semilogy([f(1) f(end)],[baseline baseline],'k--')
%         title(flag)

        rightBoundary = any(eyeX>(X-buffer(1)));
        leftBoundary = any(eyeX<(0+buffer(1)));
        topBoundary = any(eyeY<(0+buffer(2)));
        bottomBoundary = any(eyeY>(Y-buffer(2)));
        if  any([rightBoundary,leftBoundary,topBoundary,bottomBoundary])
            continue;
        end

        %Criterion for inclusion: eye movements spanned at least 300 arcmin in
        %X and Y - s.t. there is some amt of exploration & large fixation changes
        if and(range(eyeX)>300,range(eyeY)>300)
            ct = ct + 1;
            centerTrajectory = zeros(1,length(eyeX));
            surroundTrajectory = zeros(1,length(eyeX));
            for pp = 1:length(eyeX)
                centerX = eyeX(pp);
                centerY = eyeY(pp);
                newFrame = ...
                    my_image(round(centerY-windowSize_VHpix(1)/2 + 1):round(centerY+windowSize_VHpix(1)/2),...
                    round(centerX-windowSize_VHpix(1)/2 + 1):round(centerX+windowSize_VHpix(1)/2));
                
                centerTrajectory(pp) = sum(sum(newFrame.*centerBinary)) ./ sum(centerBinary(:));
                surroundTrajectory(pp) = sum(sum(newFrame.*surroundBinary)) ./ sum(surroundBinary(:));
            end
            
            
%             figure(1); clf; subplot(211)
%             h1 = plot(eyeX, eyeY, 'Color', [0 1 0], 'LineWidth',1,'Marker','.');
%             xlim([0 w]); ylim([0 h])
%             subplot(212); hold on;
%             plot(centerTrajectory,'b');
%             plot(surroundTrajectory,'r')
%             plot([0 length(centerTrajectory)],[ImageMean ImageMean],'k--')
%             drawnow
%             pause();

            luminanceData(ct).ImageIndex = ImageIndex;
            luminanceData(ct).SubjectIndex = SubjectIndex;
            luminanceData(ct).ImageName = image_name;
            luminanceData(ct).ImageMin = ImageMin;
            luminanceData(ct).ImageMax = ImageMax;
            luminanceData(ct).ImageMean = ImageMean;
            luminanceData(ct).centerTrajectory = centerTrajectory;
            luminanceData(ct).surroundTrajectory = surroundTrajectory;
        else
            continue

        end


    end
end

toc
currentDateString = char(datetime(date,'Format','yyyyMMdd'));
save(['SaccadeLuminanceTrajectoryStimuli_',currentDateString,'.mat'],'luminanceData')