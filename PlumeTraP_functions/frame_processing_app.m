%% frame_processing_app - PlumeTraP
% Function containing the workflow to process visible wavelenghts images
% with input from GUI
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> frame_processing_app

function frame_processing_app(outFolder_proc,outFolder_orig,imageList_orig,...
    name,outFormat,mask,th_all,th_first,nousebkgr,saveprocessedframes,rgbuse_bkg,rgbuse_all)

img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name)); % read images
fprintf('%s IMAGE PROCESSING STARTED ...\n',name)

if saveprocessedframes == true
    ext_list = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
    for el = 1:length(ext_list)
        delete(fullfile(outFolder_proc,ext_list(el)))
    end
end

% Apply processing to all frames
for i = 1:length(imageList_orig)
    progress = i/length(imageList_orig);
    if i == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',i,...
            length(imageList_orig)),'Name','Processing frames','Units',...
            'normalized','Position',[0.4,0.04,0.19,0.07]);
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',i,...
            length(imageList_orig)),'Name','Processing frames','Units',...
            'normalized','Position',[0.4,0.04,0.19,0.07]);
    end

    img = imread(fullfile(outFolder_orig,imageList_orig(i).name)); % read images

    if i > 1
        img_prec = imread(fullfile(outFolder_orig,...
            imageList_orig(i-1).name)); % read images
        [~,img_bin,img_backgr,~,img_plume_holes] = image_analysis_app(img,...
            img_start,img_prec,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
    else
        [~,img_bin,img_backgr,~,img_plume_holes] = image_analysis_app(img,...
            img_start,img,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
    end

    % Save the processed image
    if saveprocessedframes == true
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

if saveprocessedframes == true
    fprintf('%s FRAMES PROCESSED & SAVED\n',name)
else
    fprintf('%s FRAMES ANALYSED\n',name)
end
close(w) % close the waitbar
beep

end