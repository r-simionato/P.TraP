%% frame_processing - PlumeTraP
% Function containing the workflow to process the visible wavelenghts images
% Author: Riccardo Simionato. Date: March 2022
% Structure: PlumeTrAP --> frame_processing

function frame_processing(outFolder_proc,outFolder_orig,imageList_orig,...
    name)

%% Set & verify processing parameters
while 1
    prompt = {'Threshold - first image [0-1]:',...
        'Threshold - all frames [0-1]:'};
    dlgtitle = 'Processing parameters';
    dims = [1 60]; % window size
    definput = {'0.10','0.10'}; % default parameters
    parameters = inputdlg(prompt,dlgtitle,dims,definput); % str2num(parameters{n}) to get the answer
    th_first = str2double(parameters{1}); % Threshold luminance value for the first frame
    th_all = str2double(parameters{2}); % Threshold luminance value for all the other frames
    nb_size = 4; % Neighborhood size for median filter
    
    % Load and process 1st frame to do the subtraction and last frame to create a mask
    img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name)); % read images
    img_end = imread(fullfile(outFolder_orig,...
        imageList_orig(length(imageList_orig)).name)); % read images
    i = length(imageList_orig)-1;
    img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i).name)); % read images
    [img_height,img_width,~] = size(img_start); % get image dimensions
    transparent_mask = ones(img_height,img_width); % create a transparent mask to use the image_analysis function
    
    [img_start_bin,~,img_end_backgr,~,img_end_plume_holes] = ...
        image_analysis(img_end,img_start,img_precEnd,i,transparent_mask,...
        th_first,th_all,nb_size);
    
    [row,col] = find(img_end_plume_holes); % find all positions where image = 1
    
    fig = figure(1);
    fig.Units = 'normalized';
    fig.Position = [0 0 1 1]; % maximize figure
    subplot(2,3,1)
    imshow(img_start_bin)
    title('First frame binarized')
    subplot(2,3,2)
    imshow(img_end_backgr)
    title('Last frame backgroud removed')
    subplot(2,3,3)
    imshow(img_end_plume_holes)
    title('Last frame plume isolation')

    % Ask if processing parameters are good
    quest = 'Confirm processing parameters?'; 
    opts.Interpreter = 'tex'; 
    opts.Default = 'Yes';
    answer = questdlg(quest,'Confirm processing parameters','Yes',...
         'Set new parameters',opts);

    if strcmp(answer,'Yes')
        subplot(2,3,4)
        imshow(img_end)
        title('ROI area')
        ROIa = images.roi.Rectangle(gca,'Position',[min(col),min(row),... 
            max(col)-min(col),max(row)-min(row)],'Color','r','LineWidth',...
            0.5,'FaceAlpha',0); % Define a region of interest of the plume dimension
        axis([0,img_width,0,img_height]) % set axis for the ROI

        % Ask if want to use the automatic ROI or draw it manually
        quest = 'Use automatic ROI?';
        opts.Interpreter = 'tex';
        opts.Default = 'Yes';
        ROI = questdlg(quest,'ROI','Yes','No, draw it',opts);

        if strcmp(ROI,'Yes')
            mask = createMask(ROIa,img_height,img_width); % create the mask
            subplot(2,3,5)
            imshow(mask)
            title('Mask')
        elseif strcmp(ROI,'No, draw it') % draw ROI manually
            while 1
                subplot(2,3,5)
                imshow(img_end)
                title('Draw ROI area (use zoom in)')
                ROIm = drawrectangle('Color','r','LineWidth',0.5,'FaceAlpha',0);
                axis([0,img_width,0,img_height])
                mask = createMask(ROIm,img_height,img_width); % create the mask
                subplot(2,3,6)
                imshow(mask)
                title('Mask')

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
    end
    
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
fprintf('%s.mp4 IMAGE PROCESSING STARTED ...\n',name)

%% Apply processing to all frames
for i = 1:length(imageList_orig)
    progress = i/length(imageList_orig);
    if i == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',i,...
            length(imageList_orig)),'Name',...
            sprintf('Processing %s.mp4 frames',name),'Position',...
            [325,140,270,50]);
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',i,...
            length(imageList_orig)),'Name',...
            sprintf('Processing %s.mp4 frames',name),'Position',...
            [325,140,270,50]);
    end
    fprintf('Processing frame %d/%d ...\n',i,length(imageList_orig))
    
    img = imread(fullfile(outFolder_orig,imageList_orig(i).name)); % read images

    if i > 1
        img_prec = imread(fullfile(outFolder_orig,...
            imageList_orig(i-1).name)); % read images
        [~,img_bin,img_backgr,~,img_plume_holes] = image_analysis(img,...
            img_start,img_prec,i,mask,th_first,th_all,nb_size);
    else 
        [~,img_bin,img_backgr,~,img_plume_holes] = image_analysis(img,...
            img_start,img,i,mask,th_first,th_all,nb_size);
    end
    
    % Save the processed image
    if strcmp(saveProcessing,'Save')
        imwrite(img_plume_holes,fullfile(outFolder_proc,...
            sprintf(imageList_orig(i).name)))
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
        imwrite(A,map,fullfile(outFolder_proc,sprintf('%s_%s-%s.gif',...
            name,parameters{1},parameters{2})),'gif','Loopcount',inf);
    else % add subsequent frames
        imwrite(A,map,fullfile(outFolder_proc,sprintf('%s_%s-%s.gif',...
            name,parameters{1},parameters{2})),'gif','WriteMode','append');
    end
end

if strcmp(saveProcessing,'Save')
    fprintf('%s.mp4 FRAMES PROCESSED & SAVED\n',name)
else
    fprintf('%s.mp4 FRAMES ANALYSED\n',name)
end
close(w) % close the waitbar
beep

end        