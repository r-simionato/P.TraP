%% frame_processing - PlumeTraP
% Function containing the workflow to process visible wavelenghts images
% Author: Riccardo Simionato. Date: February 2024
% Structure: PlumeTraP --> frame_processing

function frame_processing(outFolder_proc,outFolder_orig,imageList_orig,...
    name,outFormat)

%% Set & verify processing parameters
% ROI selection
img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name)); % read images
i = length(imageList_orig)-1;
img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i).name)); % read images
img_end = imread(fullfile(outFolder_orig,...
    imageList_orig(length(imageList_orig)).name)); % read images
[img_height,img_width,~] = size(img_end); % get image dimensions
mask = ones(img_height,img_width);
[~,~,~,~,img_end_plume_holes] = ...
    image_analysis(img_end,img_start,img_precEnd,i,mask,0.1,0.1);
[row,col] = find(img_end_plume_holes); % find all positions where image = 1

figROI = figure(100);
subplot(1,1,1)
imshow(img_end)
title('ROI area')
if isempty(row) || isempty(col)
    ROIa = images.roi.Rectangle(gca,'Position',[1,1,...
        img_width,img_height],'Color','r','LineWidth',...
        0.5,'FaceAlpha',0);
else
    ROIa = images.roi.Rectangle(gca,'Position',[min(col),min(row),...
        max(col)-min(col),max(row)-min(row)],'Color','r','LineWidth',...
        0.5,'FaceAlpha',0); % Define a region of interest of the plume dimension
end
axis([0,img_width,0,img_height]) % set axis for the ROI

% Ask if want to use the automatic ROI or draw it manually
quest = 'Use automatic ROI?';
opts.Interpreter = 'tex';
opts.Default = 'Yes';
ROI = questdlg(quest,'ROI','Yes','No, draw it',opts);

if strcmp(ROI,'Yes')
    mask = createMask(ROIa,img_height,img_width); % create the mask

elseif strcmp(ROI,'No, draw it') % draw ROI manually
    while 1
        subplot(1,1,1)
        imshow(img_end)
        title('Draw ROI area (use zoom in)')
        ROIm = drawrectangle('Color','r','LineWidth',0.5,'FaceAlpha',0);
        axis([0,img_width,0,img_height])
        mask = createMask(ROIm,img_height,img_width); % create the mask

        % Asks if ROI is good
        quest = 'Do you want to proceed with this ROI?';
        opts.Interpreter = 'tex';
        opts.Default = 'Yes';
        drawnROI = questdlg(quest,'Confirm ROI selection','Yes',...
            'Draw new ROI',opts);
        if strcmp(drawnROI,'Yes') % stops the while loop if the drawn ROI is good
            break
        end
    end
end
close(figROI)

[r,~,b] = imsplit(img_start); % split colour channels
mean_img = mean2(b-r);
if mean_img > 5
    channels = 'blue-red subtraction';
else
    channels = 'blue channel only';
end
while 1
    prompt = {sprintf('Threshold - first frame [0-100]:    (%s)',channels),...
        sprintf('Threshold - all frames [0-100]:    (%s)',channels)};
    dlgtitle = ('Processing parameters');
    dims = [1 60]; % window size
    definput = {'10','10'}; % default parameters
    parameters = inputdlg(prompt,dlgtitle,dims,definput); % str2num(parameters{n}) to get the answer
    th_first = str2double(parameters{1})/100; % Threshold luminance value for the first frame
    th_all = str2double(parameters{2})/100; % Threshold luminance value for all the other frames

    % Process 1st and last frame
    [img_start_bin,~,~,~,img_end_plume_holes] = ...
        image_analysis(img_end,img_start,img_precEnd,i,mask,...
        th_first,th_all);

    % Load and process 2nd frame
    img2 = imread(fullfile(outFolder_orig,imageList_orig(2).name)); % read images
    i = 2;
    [~,~,~,~,img2_plume_holes] = image_analysis(img2,...
        img_start,img_start,i,mask,th_first,th_all);

    fig = figure(1);
    fig.Units = 'normalized';
    fig.Position = [0.05 0.02 0.9 0.9]; % maximize figure
    subplot(2,2,1)
    imshow(img_start)
    title('First frame')
    subplot(2,2,2)
    imshow(img_start_bin)
    title('First frame binarized')
    subplot(2,2,3)
    imshow(img2_plume_holes)
    title('Second frame plume isolation')
    subplot(2,2,4)
    imshow(img_end_plume_holes)
    title('Last frame plume isolation')

    % Ask if processing parameters are good
    pause(2)
    quest = 'Confirm processing parameters?';
    opts.Interpreter = 'tex';
    opts.Default = 'Yes';
    answer = questdlg(quest,'Confirm processing parameters','Yes',...
        'Set new parameters',opts);

    if strcmp(answer,'Yes') % stops the while loop if satisfied with parameters
        break
    end
end

% Asks if want to save or not processed frames
quest = 'Save frames after processing?';
opts.Interpreter  =  'tex';
opts.Default  =  'Save';
saveProcessing = questdlg(quest,'Processed frames','Save','Show only',...
    opts);
fprintf('%s IMAGE PROCESSING STARTED ...\n',name)
if strcmp(saveProcessing,'Save')
    ext_list = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
    for el = 1:length(ext_list)
        delete(fullfile(outFolder_proc,ext_list(el)))
    end
end

%% Apply processing to all frames
for i = 1:length(imageList_orig)
    progress = i/length(imageList_orig);
    if i == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',i,...
            length(imageList_orig)),'Name','Processing frames');
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',i,...
            length(imageList_orig)),'Name','Processing frames');
    end

    img = imread(fullfile(outFolder_orig,imageList_orig(i).name)); % read images

    if i > 1
        img_prec = imread(fullfile(outFolder_orig,...
            imageList_orig(i-1).name)); % read images
        [~,img_bin,img_backgr,~,img_plume_holes] = image_analysis(img,...
            img_start,img_prec,i,mask,th_first,th_all);
    else
        [~,img_bin,img_backgr,~,img_plume_holes] = image_analysis(img,...
            img_start,img,i,mask,th_first,th_all);
    end

    % Save the processed image
    if strcmp(saveProcessing,'Save')
        [~,filename,~] = fileparts(fullfile(outFolder_proc,...
            sprintf(imageList_orig(i).name)));
        imwrite(img_plume_holes,fullfile(outFolder_proc,...
            sprintf('%s%s',filename,outFormat(2:end))))
    end

    % Show processing steps
    figure(2)
    subplot(2,2,1)
    imshow(img)
    title('Original frame')
    subplot(2,2,2)
    imshow(img_bin)
    title('Binarization')
    subplot(2,2,3)
    imshow(img_backgr)
    title('Background removal')
    subplot(2,2,4)
    imshow(img_plume_holes)
    title('Plume isolation')
    % Capture the plot as a GIF image
    fig = figure(2);
    plot_frame = getframe(fig);
    plot_image = frame2im(plot_frame);
    [A,map] = rgb2ind(plot_image,256);
    if i == 1 % save first frame of the .gif
        imwrite(A,map,fullfile(outFolder_proc,sprintf('%s_%d-%d.gif',...
            name,th_all*100,th_first*100)),'gif','Loopcount',inf);
    else % add subsequent frames
        imwrite(A,map,fullfile(outFolder_proc,sprintf('%s_%d-%d.gif',...
            name,th_all*100,th_first*100)),'gif','WriteMode','append');
    end
end

if strcmp(saveProcessing,'Save')
    fprintf('%s FRAMES PROCESSED & SAVED\n',name)
else
    fprintf('%s FRAMES ANALYSED\n',name)
end
close(w) % close the waitbar
beep

end