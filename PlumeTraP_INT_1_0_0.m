%% PlumeTrAP v1.0.0 - Interactive version %%
% Detection and parameterization of volcanic plumes in visible videos.
% Starting from a video, frames are saved, segmented through a specific
% technique and basilar parameters of the plume through time are extracted.
%
% Author: Riccardo Simionato. Date: March 2022
% Developed with MatLab R2018b and Image Processing Toolbox 10.3
% Tested and operative up to R2021b MatLab version

clc; clearvars; close all;

%% Select video(s)
h = helpdlg('Select one or more videos','PlumeTraP');
uiwait(h)
opts = struct('WindowStyle','modal','Interpreter','tex');
while 1
    [videos,inFolder] = uigetfile('*.*','Select One or More Videos',...
        'MultiSelect','on');
    if isequal(isequal(videos,0),0)
        break
    end
    opts.Default = 'OK';
    q = questdlg('Select one or more videos in the opening window',...
        'PlumeTraP','OK','Stop execution',opts);
    if strcmp(q,'Stop execution')
        break
    end
end
videos = cellstr(strcat(inFolder, videos)); % convert character value into cell array

%% Start the process
for v = 1:length(videos) % start a loop of number of videos cycles
    %% 
    w = waitbar(0,sprintf('Reading video %d/%d ...',v,length(videos)),'Name',...
        'Reading video...');
    fprintf('READING VIDEO %d/%d ...\n',v,length(videos))
    
    vid = VideoReader(videos{v}); %read the video
    n = vid.NumberOfFrames; %get total number of frames
    fr = round(vid.FrameRate); %get frame rate to process a frame per second
    [~,name,ext] = fileparts(videos{v}); %extract name without extension
    prompt = {'Save videos frames [y/n]:',... %alg{1}
        'Analyse frames [y/n]:',... %alg{2}
        'Extract parameters [y/n]:'}; %alg{3}
    dlgtitle = 'Workflow'; dims = [1 50]; % window title & size
    definput = {'y','y','y'}; % default parameters
    alg = inputdlg(prompt,dlgtitle,dims,definput);
    
    waitbar(1,w,sprintf('%s%s ready',name,ext),'Name','Reading video...');
    fprintf('VIDEO %s%s READY\n',name,ext)
    close(w)
    
    h = helpdlg('Select a main folder path (outputs will be saved here in two subfolders)','PlumeTraP');
    uiwait(h)
    while 1
        outFolder = uigetdir(inFolder,...
            'Select the main folder to save outputs'); % that before the folder with the name of the video
        if isequal(isequal(outFolder,0),0)
            break
        end
        opts.Default = 'OK';
        q = questdlg('Select the main folder path where outputs will be saved',...
            'PlumeTraP','OK','Stop execution',opts);
        if strcmp(q,'Stop execution')
            break
        end
    end

    %% Frames extraction
    if alg{1}=='y'
        outFolder_orig = fullfile(outFolder,name,...
            sprintf('%s_Frames',name)); % set name of output folder
        mkdir(outFolder_orig) % create output folder
        fprintf('%s%s FRAME EXTRACTION PROCESS STARTED ...\n',name,ext)
        
        prompt = {'Scale factor n (save n frames per second):','Output image format:'}; %fr_ext{1} & fr_ext{2}
        dlgtitle = 'Frames extraction'; dims = [1 60]; % window title & size
        definput = {'1','*.png'}; % default parameters
        fr_ext = inputdlg(prompt,dlgtitle,dims,definput);
        scale_fr = str2double(fr_ext{1});
        ImageFormat = fr_ext{2};
                
        frame_extraction(vid,name,fr,scale_fr,n,outFolder_orig,ImageFormat);
        
    elseif alg{1} == 'n' && alg{2} == 'y' % load previosly saved frames just in case analysis is needed
        h = helpdlg('Select the folder path where frames are saved','PlumeTraP');
        uiwait(h)
        while 1
            outFolder_orig = uigetdir(inFolder,...
                sprintf('Select %s%s frames folder',name,ext)); % select the folder where orgignal frames are saved
            if isequal(isequal(outFolder_orig,0),0)
                break
            end
            opts.Default = 'OK';
            q = questdlg('Select the folder path where frames are saved',...
                'PlumeTraP','OK','Stop execution',opts);
            if strcmp(q,'Stop execution')
                break
            end
        end

        prompt = {'Scale factor n:','Image format:'}; %fr_ext{1} & fr_ext{2}
        dlgtitle = 'Frames parameters'; dims = [1 60]; % window title & size
        definput = {'1','*.png'}; % default parameters
        fr_ext = inputdlg(prompt,dlgtitle,dims,definput);
        scale_fr = str2double(fr_ext{1});
        ImageFormat = fr_ext{2};
        
        w = waitbar(1,sprintf('Loading %s%s frames ...',name,ext),'Name',...
            'Loading frames...');
        pause(1)
        fprintf('LOADING %s%s FRAMES ...\n',name,ext)
        close(w) % close the waitbar
    end

    %% Frames processing
    outFolder_proc = fullfile(outFolder,name,sprintf('%s_Processed',name));
    mkdir(outFolder_proc)
    
    if alg{2} == 'y'
        imageList_orig = dir(fullfile(outFolder_orig,ImageFormat)); % read images

        frame_processing(outFolder_proc,outFolder_orig,...
            imageList_orig,name);
        
    elseif alg{2} == 'n' && alg{3} == 'y' % load previosly analysed frames
        h = helpdlg('Select the folder path where analysed frames are saved','PlumeTraP');
        uiwait(h)
        while 1
            outFolder_proc = uigetdir(inFolder,...
                sprintf('Select %s%s analysed frames folder',name,ext)); % select the folder where orgignal frames are saved
            if isequal(isequal(outFolder_proc,0),0)
                break
            end
            opts.Default = 'OK';
            q = questdlg('Select the folder path where analysed frames are saved',...
                'PlumeTraP','OK','Stop execution',opts);
            if strcmp(q,'Stop execution')
                break
            end
        end

        prompt = {'Scale factor n:','Image format:'}; %fr_ext{1} & fr_ext{2}
        dlgtitle = 'Frames parameters'; dims = [1 60]; % window title & size
        definput = {'1','*.png'}; % default parameters
        fr_ext = inputdlg(prompt,dlgtitle,dims,definput);
        scale_fr = str2double(fr_ext{1});
        ImageFormat = fr_ext{2};
        
        imageList_orig = dir(fullfile(outFolder_orig,ImageFormat)); % read images

        w = waitbar(1,sprintf('Loading %s%s frames ...',name,ext),'Name',...
            'Loading frames...');
        pause(1)
        fprintf('LOADING %s%s FRAMES ...\n',name,ext)
        close(w) % close the waitbar
    end
    
    %% Calibration & calculation of plume parameters
    if alg{3} == 'y'
        imageList_proc = dir(fullfile(outFolder_proc,ImageFormat)); % read images
        outFolder_parameters = fullfile(outFolder,name);
        [imgplume_height,imgplume_width] = ...
            size(imread(fullfile(outFolder_proc,imageList_proc(1).name)));
        
        %% Geometrical calibration
        % Set input parameters
        prompt = {'Minimum distance from the vent [m]:',... 
            'Maximum distance from the vent [m]:',... 
            'Horizontal lens angle [°]:',... 
            'Vertical lens angle [°]:',... 
            'Camera inclination [°]:'};
        dlgtitle = 'Geometrical calibration parameters'; dims = [1 70]; % window title & size
        definput = {'','','','',''}; % insert here default values
        corr = inputdlg(prompt,dlgtitle,dims,definput);
        
        par.min_dist = str2double(corr{1}); % Minimum distance from the camera to the image plane
        par.max_dist = str2double(corr{2}); % Maximum distance from the camera to the image plane
        par.beta_h = str2double(corr{3}); % Horizontal FOV
        par.beta_v = str2double(corr{4}); % Vertical FOV
        par.phi = str2double(corr{5}); % Camera inclination
        par.beta_v_pixel = par.beta_v/imgplume_height; % Determine the vertical angle subtended by each pixel
        par.beta_h_pixel = par.beta_h/imgplume_width; % Determine the horizontal angle subtended by each pixel

        % Apply geometrical calibration
        [pixel] = ...
            geometrical_calibration(imgplume_height,imgplume_width,par);
        
        %% Get & save plume parameters
        [height,width,plots,velocity,acceleration,tables] = ...
            plume_parameters(scale_fr,alg{2},name,outFolder_orig,...
            imageList_orig,outFolder_proc,imageList_proc,...
            outFolder_parameters,imgplume_height,pixel);
        
    end
    beep
    if length(list) > 1
        close all
    end
end