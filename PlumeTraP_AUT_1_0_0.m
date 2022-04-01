%% PlumeTraP v1.0.0 - Semi-automatic %%
% Detection and parameterization of volcanic plumes in visible videos.
% Starting from a video, frames are saved, segmented through a specific 
% technique and basilar parameters of the plume through time are extracted.
%
% Author: Riccardo Simionato. Date: March 2022
% Developed with MatLab R2018b and Image Processing Toolbox 10.3
% Tested and operative up to R2021b MatLab version

clc; clearvars; close all;

%% Edit input files
% Path of the video(s)
    inFolder = 'C:\Users\simio\OneDrive\Documenti\Università\Geneva\Analysis\Process\';
    VideoFormat = '*.mp4';
    
% Select the main output folder
    outFolder = 'C:\Users\simio\OneDrive\Documenti\Università\Geneva\Analysis\Process\';
% Select the output file format for the images (PNG is recommended)
    ImageFormat = '*.png';

% Parts of the algorithm to be run ('y' to run, 'n' to skip)
    saveframes = 'n'; % Save n frames per second
        scale_fr = 1; % Set scale factor to save n frames per second
    procframes = 'n'; % Apply image processing to the frame
    parameters = 'y'; % Extract parameters from the image C:\Users\simio\OneDrive\Documenti\Università\Geneva\Analysis\Process

% Geometrical calibration 
    cal = 'c'; % 'c' to calibrate basing on geometrical data, 'u' to upload already calibrated data
        % If cal = c: path of the file to calibrate basing on geometrical data (.txt or .csv file)
            GeometricalData = 'C:\Users\simio\OneDrive\Documenti\Università\Geneva\Analysis\Process\DATAFILE_Sabancaya.txt';
        % If cal = u: path of the file containing the calibrated data (.txt or .csv file)
            HorizontalCalibratedData = 'C:\PlumeTraP\Videos\h_calibrated_parameters.txt';
            VerticalCalibratedData = 'C:\PlumeTraP\Videos\h_calibrated_parameters.txt';
        % set equal to nan or comment depending on how the calibration is made (e.g., GeometricalData = nan)

%% Start the process
list = (dir(fullfile(inFolder,VideoFormat))); %list of the files and their info

for v = 1:length(list) % start a loop of number of videos cycles
    %% Reading video
    w = waitbar(0,sprintf('Reading video %d/%d ...',v,length(list)),'Name',...
            'Reading video...');
    fprintf('READING VIDEO %d/%d ...\n',v,length(list))
    
    videos(v) = cellstr(strcat(inFolder,list(v).name)); %create list of the videos
    vid = VideoReader(videos{v}); %read the video
    n = vid.NumberOfFrames; %get total number of frames
    fr = round(vid.FrameRate); %get frame rate to process a frame per second
    [~,name,ext] = fileparts(videos{v}); %extract name without extension
    
    waitbar(1,w,sprintf('%s%s ready',name,ext),'Name','Reading video...');
    fprintf('VIDEO %s%s READY\n',name,ext)
    close(w)
  
    %% Frames extraction
    outFolder_orig = fullfile(outFolder,name,sprintf('%s_Frames',name)); % select the output folder or that where the frames are already saved
    
    if saveframes == 'y'
        mkdir(outFolder_orig) % create output folder
        fprintf('%s%s FRAME EXTRACTION PROCESS STARTED ...\n',name,ext)

        frame_extraction(vid,name,fr,scale_fr,n,outFolder_orig,ImageFormat);
     
    elseif saveframes == 'n' && procframes == 'y' % loading already saved frames waitbar
        w = waitbar(1,sprintf('Loading %s%s frames ...',name,ext),'Name',...
            'Loading frames...');
        pause(1)
        fprintf('LOADING %s%s FRAMES ...\n',name,ext)
        close(w) % close the waitbar
    end
    
    %% Frames processing
    outFolder_proc = fullfile(outFolder,name,sprintf('%s_Processed',name)); % select the output folder or that where processed frames are saved
    mkdir(outFolder_proc)
    
    if procframes == 'y'
        imageList_orig = dir(fullfile(outFolder_orig,ImageFormat)); % read saved frames
        
        frame_processing(outFolder_proc,outFolder_orig,imageList_orig,name);
        
    elseif procframes == 'n' && parameters == 'y' % loading already analysed frames waitbar
        imageList_orig = dir(fullfile(outFolder_orig,ImageFormat)); % read saved frames

        w = waitbar(1,sprintf('Loading %s%s frames ...',name,ext),'Name',...
            'Loading frames...');
        pause(1)
        fprintf('LOADING %s%s FRAMES ...\n',name,ext)
        close(w) % close the waitbar
    end
    
    %% Calibration & calculation of plume parameters
    if parameters == 'y'
        imageList_proc = dir(fullfile(outFolder_proc,ImageFormat)); % read images
        outFolder_parameters = fullfile(outFolder,name);
        [imgplume_height,imgplume_width] = ...
            size(imread(fullfile(outFolder_proc,imageList_proc(1).name)));
        
        %% Geometrical calibration
        if cal =='c' % Calibrate basing on geometrical data
            % Set input parameters
            geometrical_data = textscan(fopen(GeometricalData),...
                '%s %.f %.f %.1f %.1f %.f'); % Read data as a table with columns with different format
            for V = 1:size(geometrical_data{1},1)
                if isequal(char(geometrical_data{1}(V)),name)
                    par.min_dist = geometrical_data{2}(V); % Minimum distance from the camera to the image plane
                    par.max_dist = geometrical_data{3}(V); % Maximum distance from the camera to the image plane
                    par.beta_h = geometrical_data{4}(V); % Horizontal FOV
                    par.beta_v = geometrical_data{5}(V); % Vertical FOV
                    par.phi = geometrical_data{6}(V); % Camera inclination
                end
            end
            par.beta_v_pixel = par.beta_v/imgplume_height; % Determine the vertical angle subtended by each pixel
            par.beta_h_pixel = par.beta_h/imgplume_width; % Determine the horizontal angle subtended by each pixel

            % Apply geometrical calibration
            [pixel] = ...
                geometrical_calibration(imgplume_height,imgplume_width,par);

        elseif cal == 'u' % Use calibration file
            h_cal = table2array(readtable(HorizontalCalibratedData)); % Read data file as an array
            pixel.x = h_cal(1,1:imgplume_width);
            pixel.x_err = h_cal(2,1:imgplume_width);

            v_cal = flip(transpose(table2array...
                (readtable(VerticalCalibratedData)))); % Read data file as an array, then transpose (.') and flip
            pixel.z = v_cal(1:imgplume_height,1);
            pixel.z_err = v_cal(1:imgplume_height,2);
        end

        %% Get & save plume parameters
        [height,width,plots,velocity,acceleration,tables] = ...
            plume_parameters(scale_fr,procframes,name,outFolder_orig,...
            imageList_orig,outFolder_proc,imageList_proc,...
            outFolder_parameters,imgplume_height,pixel);

    end
    beep
    if length(list) > 1
        close all
    end
end