%% PlumeTraP 2.1.0 - Main script executed by PlumeTraP.mlapp %%
% Detection and parameterization of volcanic plumes in visible videos.
% Starting from a video, frames are saved, segmentated through a specific
% technique and basilar parameters of the plume through time are extracted.

% Copyright (C) 2024 Riccardo Simionato
% Last updated: May 2024
% Developed with MATLAB R2023b and Image Processing Toolbox 23.2

clc; close all;
fprintf('PlumeTraP 2.1.0\nCopyright (C) 2024 Riccardo Simionato\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the\nGNU General Public License as published by the Free Software Foundation, either version 3 of the\nLicense, or (at your option) any later version.\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;\nwithout even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\nSee the GNU General Public License for more details (https://www.gnu.org/licenses/gpl-3.0.html).\n\n')
addpath(genpath(pwd))
warning('off','MATLAB:MKDIR:DirectoryExists')

%% Start the process
if source == 'v'
    list = files;                                                           % list of the videos and their info
    path = cell(1,length(files));
elseif source == 'i'
    list = 1;
end

for v = 1:length(list)                                                      % start a loop of number of videos cycles
    %% Reading video
    if source == 'v'
        w = waitbar(0,sprintf('Reading video %d/%d',v,length(list)),'Name',...
            'Reading video');

        path(v) = cellstr(strcat(inFolder,files{v}));                       % path of the video
        vid = VideoReader(path{v});                                         % read the video
        n = vid.NumFrames;                                                  % get total number of frames    % to cut video use n = 15*fr;
        fr = round(vid.FrameRate);                                          % get frame rate to process n frames per second
        [~,name,ext] = fileparts(path{v});                                  % extract name without extension
        waitbar(1,w,'Video ready','Name','Reading video');
        fprintf('VIDEO %s%s READY\n',name,ext)
        close(w)

        %% Frames extraction
        outFolder_orig = fullfile(outFolder,name,sprintf('%s_Frames',name)); % select the output folder or that where the frames are already saved

        if saveframes == 1
            mkdir(outFolder_orig)                                           % create output folder
            addpath(outFolder_orig)
            fprintf('%s%s FRAME EXTRACTION PROCESS STARTED\n',name,ext)

            frame_extraction(vid,name,fr,scale_fr,n,outFolder_orig,outFormat);

        elseif saveframes == 0 && procframes == 1                           % loading already saved frames waitbar
            w = waitbar(1,'Loading frames','Name','Loading frames');
            pause(1)
            fprintf('LOADING %s%s FRAMES\n',name,ext)
            close(w)                                                        % close the waitbar
        end

    elseif source == 'i'
        outFolder_orig = inFolder;
        [~,name,~] = fileparts(files{1});
        if name(length(name)-6) == "-"
            name = name(1:length(name)-7);
        else
            prompt = {'Name of images set:'};
            dlgtitle = 'Specify Name'; dims = [1 60];
            name_out = inputdlg(prompt,dlgtitle,dims);
            name = string(name_out{1});
        end
    end

    %% Frames processing
    if procframes == 1
        if source == 'v'
            imageList_orig = dir(fullfile(outFolder_orig,outFormat));       % read saved frames
            while isempty(imageList_orig)
                inFormat_img = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
                for img_ext = 1:length(inFormat_img)
                    imageList_orig = dir(fullfile(outFolder_orig,inFormat_img(img_ext)));
                    if ~isempty(imageList_orig)
                        break
                    end
                end
            end
        elseif source == 'i'
            imageList_orig = dir(fullfile(outFolder_orig,inFormat));        % read saved frames
        end

        appFP = app_FrameProcessing;
        waitfor(appFP)

        if mantrack == 0
            outFolder_proc = fullfile(outFolder,name,sprintf('%s_Processed',name)); % select the output folder or that where processed frames are saved
            mkdir(outFolder_proc)
            addpath(outFolder_proc)

            frame_processing_app(outFolder_proc,outFolder_orig,imageList_orig,...
                name,outFormat,mask,th_all,th_first,nousebkgr,...
                saveprocessedframes,rgbuse_bkg,rgbuse_all);

        elseif mantrack == 1
            outFolder_proc = outFolder_orig;
        end

    elseif procframes == 0 && parameters == 1                                   % loading already analysed frames waitbar
        outFolder_proc = fullfile(outFolder,name,sprintf('%s_Processed',name)); % select the output folder or that where processed frames are saved
        imageList_orig = dir(fullfile(outFolder_orig,outFormat));           % read saved frames
        mantrack = false;
        while isempty(imageList_orig)
            inFormat_img = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
            for img_ext = 1:length(inFormat_img)
                imageList_orig = dir(fullfile(outFolder_orig,inFormat_img(img_ext)));
                if ~isempty(imageList_orig)
                    break
                end
            end
        end

        img_end = imread(fullfile(outFolder_proc,imageList_proc(length(imageList_proc)).name));
        [row,col] = find(img_end);
        roiPos = [min(col) min(row) max(col)-min(col) max(row)-min(row)];

        w = waitbar(1,'Loading frames','Name','Loading frames');
        pause(1)
        fprintf('LOADING %s FRAMES ...\n',name)
        close(w)
    end

    %% Corrections & calculation of plume parameters
    if parameters == 1
        imageList_proc = dir(fullfile(outFolder_proc,outFormat));           % read images
        if isempty(imageList_proc) && source == 'i'
            imageList_proc = dir(fullfile(outFolder_proc,inFormat));
        elseif mantrack == 1
            imageList_proc = imageList_orig;
        end
        outFolder_parameters = fullfile(outFolder,name);
        mkdir(outFolder_parameters)
        [imgplume_height,imgplume_width,~] = ...
            size(imread(fullfile(outFolder_proc,imageList_proc(1).name)));

        appVP = app_VentPosition;
        waitfor(appVP)
        pixel.vent_pos_x = VentPos_x;
        pixel.vent_pos_y = VentPos_y;

        %% Corrections
        % if gcal == 'c' || gcal == 'i'
        % Set input parameters
        if gcal == 'c'
            geometrical_data = textscan(fopen(GeometricalData),...
                '%s %.f %.f %.1f %.1f %.f %.2f %s %s %.1f %.2f %.2f %.f'); % Read data as a table with columns with different format
            for V = 1:size(geometrical_data{1},1)
                if isequal(char(geometrical_data{1}(V)),name)
                    par.min_dist = geometrical_data{2}(V);              % Minimum distance from the camera to the image plane
                    par.max_dist = geometrical_data{3}(V);              % Maximum distance from the camera to the image plane
                    par.beta_h = geometrical_data{4}(V);                % Horizontal FOV
                    par.beta_v = geometrical_data{5}(V);                % Vertical FOV
                    par.phi = geometrical_data{6}(V);                   % Camera inclination
                    if wcor == 1
                        par.omega = geometrical_data{7}(V);             % Camera orientation
                        par.UTCdaytime = datetime(...                   % Day of the eruption (dd-Mmm-yyyy) and approximated to the hour time of the eruption (hh:00:00)
                            string(geometrical_data{8}(V))+' '+...
                            string(geometrical_data{9}(V)),...
                            'InputFormat','dd-MMM-yyyy HH:mm:ss');
                        par.wind_met = geometrical_data{10}(V);             % Wind direction if known (otherwise set NaN in the column and use .nc files from ERA5)
                        par.vent_lat = geometrical_data{11}(V);         % Approximate latitude (decimal)
                        par.vent_long = geometrical_data{12}(V);        % Approximate longitude (decimal)
                        par.vent_h = geometrical_data{13}(V);           % Vent height
                    end
                end
            end
            par.beta_h_pixel = par.beta_h/imgplume_width;                   % Determine the horizontal angle subtended by each pixel
            par.beta_v_pixel = par.beta_v/imgplume_height;                  % Determine the vertical angle subtended by each pixel

        elseif gcal == 'i'
            par.min_dist = par_min_dist;                                % Minimum distance from the camera to the image plane
            par.max_dist = par_max_dist;                                % Maximum distance from the camera to the image plane
            par.beta_h = par_beta_h;                                    % Horizontal FOV
            par.beta_v = par_beta_v;                                    % Vertical FOV
            par.phi = par_phi;                                          % Camera inclination
            if wcor == 1
                par.omega = par_omega;                                  % Camera orientation
                par.wind_met = par_wind;                                % Wind direction if known (otherwise set NaN in the column and use .nc files from ERA5)
                if isnan(par_wind)
                    par.vent_lat = par_vent_lat;                        % Approximate latitude (decimal)
                    par.vent_long = par_vent_long;                      % Approximate longitude (decimal)
                    par.vent_h = par_vent_h;                            % Vent height
                    par.UTCdaytime = datetime(...                       % Day of the eruption (dd-Mmm-yyyy) and approximated to the hour time of the eruption (hh:00:00)
                        string(par_date)+' '+string(par_time),...
                        'InputFormat','dd-MMM-yyyy HH:mm:ss');
                end
            end
            par.beta_h_pixel = par.beta_h/imgplume_width;                   % Determine the horizontal angle subtended by each pixel
            par.beta_v_pixel = par.beta_v/imgplume_height;                  % Determine the vertical angle subtended by each pixel

        elseif gcal == 'u'                                                  % Use calibration file
            h_cal = table2array(readtable(HorizontalCalibratedData));       % Read data file as an array
            pixel.x = h_cal(1,1:imgplume_width);
            pixel.x_err = h_cal(2,1:imgplume_width);

            v_cal = flip(transpose(table2array...
                (readtable(VerticalCalibratedData))));                      % Read data file as an array, then transpose (.') and flip
            pixel.z = v_cal(1:imgplume_height,1);
            pixel.z_err = v_cal(1:imgplume_height,2);

            if wcor == 1
                par.beta_h = par_beta_h;                                    % Horizontal FOV
                par.beta_v = par_beta_v;                                    % Vertical FOV
                par.phi = par_phi;                                          % Camera inclination
                par.omega = par_omega;                                      % Camera orientation
                par.vent_lat = par_vent_lat;                                % Approximate latitude (decimal)
                par.vent_long = par_vent_long;                              % Approximate longitude (decimal)
                par.vent_h = par_vent_h;                                    % Vent height
                par.wind_met = par_wind;                                    % Wind direction if known (otherwise set NaN in the column and use .nc files from ERA5)
                if isnan(par_wind)
                    par.UTCdaytime = datetime(...                           % Day of the eruption (dd-Mmm-yyyy) and approximated to the hour time of the eruption (hh:00:00)
                        string(par_date)+' '+string(par_time),...
                        'InputFormat','dd-MMM-yyyy HH:mm:ss');
                end
                par.beta_h_pixel = par.beta_h/imgplume_width;               % Determine the horizontal angle subtended by each pixel
                par.beta_v_pixel = par.beta_v/imgplume_height;              % Determine the vertical angle subtended by each pixel
            end
        end

        [pixel,wdir] = calibration_app(gcal,wcor,procframes,outFolder_proc,...
            imageList_proc,outFolder_parameters,imgplume_height,...
            imgplume_width,par,geopot_nc,wind_nc,pixel,roiPos,name);

        %% Get & save plume parameters
        if mantrack == 0
            if wcor == 0 || isequal(wdir,'parallel')
                [height,width,plots,velocity,acceleration,tables] = ...
                    plume_parameters_app(scale_fr,procframes,name,...
                    outFolder_proc,imageList_proc,outFolder_parameters,...
                    imgplume_height,pixel);
            elseif wcor == 1 && not(isequal(wdir,'parallel'))
                [height,width,plots,velocity,acceleration,tables] = ...
                    plume_parameters_w(scale_fr,procframes,name,outFolder_proc,...
                    imageList_proc,outFolder_parameters,imgplume_height,pixel);
            end
        elseif mantrack == 1
            %% Manual tracking of plume height (automatic calculation of velocity and acceleration)
            if wcor == 0 || isequal(wdir,'parallel')
                [height,velocity,acceleration,tables,pixel] = ...
                    manual_tracking(scale_fr,name,outFolder_proc,...
                    imageList_proc,outFolder_parameters,pixel);
            elseif wcor == 1 && not(isequal(wdir,'parallel'))
                [height,velocity,acceleration,tables,pixel] = ...
                    manual_tracking_w(scale_fr,name,outFolder_proc,...
                    imageList_proc,outFolder_parameters,pixel);
            end
        end
    end
    beep
    if length(list) > 1 && isequal(isequal(length(list),v),0)
        close all
        clear pixel par
    end
end
warning('on','MATLAB:MKDIR:DirectoryExists')