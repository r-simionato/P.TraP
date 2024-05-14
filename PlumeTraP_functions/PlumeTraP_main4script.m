%% PlumeTraP 2.1.0 - Main function executed by PlumeTraP_script.m %%
% Copyright (C) 2024 Riccardo Simionato
% Last updated: May 2024

function PlumeTraP_main4script...
    (source,inFolder,name,inFormat,outFolder,outFormat,...
    saveframes,procframes,parameters,scale_fr,...
    gcal,GeometricalData,HorizontalCalibratedData,VerticalCalibratedData,...
    wcor,geopot_nc,wind_nc,WindData)

fprintf('PlumeTraP 2.1.0\nCopyright (C) 2024 Riccardo Simionato\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the\nGNU General Public License as published by the Free Software Foundation, either version 3 of the\nLicense, or (at your option) any later version.\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;\nwithout even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\nSee the GNU General Public License for more details (https://www.gnu.org/licenses/gpl-3.0.html).\n\n')
warning('off','MATLAB:MKDIR:DirectoryExists')

if source == 'v'
    list = (dir(fullfile(inFolder,inFormat)));                              % list of the videos and their info
    path = cell(1,length(list));
    if isempty(list)
        error('Input folder is empty or check specified video format')
    end
    if inFolder(end) ~= '\'
        error('Line 27: InFolder variable must terminate with ''\''')
    end
elseif source == 'i'
    list = 1;
else
    error('Line 24: input must be ''v'' or ''i''')
end

for v = 1:length(list)                                                      % start a loop of number of videos cycles
    %% Reading video
    if source == 'v'
        w = waitbar(0,sprintf('Reading video %d/%d',v,length(list)),'Name',...
            'Reading video');
        fprintf('READING VIDEO %d/%d\n',v,length(list))

        path(v) = cellstr(strcat(inFolder,list(v).name));                   % create list of the videos
        vid = VideoReader(path{v});                                         % read the video
        n = vid.NumFrames;                                                  % get total number of frames    % to cut video use n = 15*fr;
        fr = round(vid.FrameRate);                                          % get frame rate to process n frames per second
        [~,name,ext] = fileparts(path{v});                                  % extract name without extension
        waitbar(1,w,'Video ready','Name','Reading video');
        fprintf('VIDEO %s%s READY\n',name,ext)
        close(w)

        %% Frames extraction
        outFolder_orig = fullfile(outFolder,name,sprintf('%s_Frames',name)); % select the output folder or that where the frames are already saved

        if saveframes == true
            mkdir(outFolder_orig)                                           % create output folder
            addpath(outFolder_orig)
            fprintf('%s%s FRAME EXTRACTION PROCESS STARTED ...\n',name,ext)

            frame_extraction(vid,name,fr,scale_fr,n,outFolder_orig,outFormat);

        elseif saveframes == false && procframes == true                    % loading already saved frames waitbar
            w = waitbar(1,'Loading frames','Name','Loading frames...');
            pause(1)
            fprintf('LOADING %s%s FRAMES ...\n',name,ext)
            close(w)                                                        % close the waitbar
        end

    elseif source == 'i'
        outFolder_orig = inFolder;
    end

    %% Frames processing
    outFolder_proc = fullfile(outFolder,name,sprintf('%s_Processed',name)); % select the output folder or that where processed frames are saved
    mkdir(outFolder_proc)
    addpath(outFolder_proc)
    
    if procframes == true
        imageList_orig = dir(fullfile(outFolder_orig,outFormat));           % read saved frames
        while isempty(imageList_orig)
            inFormat_img = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
            for img_ext = 1:length(inFormat_img)
                imageList_orig = dir(fullfile(outFolder_orig,inFormat_img(img_ext)));
                if ~isempty(imageList_orig)
                    break
                end
            end
        end

        frame_processing(outFolder_proc,outFolder_orig,imageList_orig,name,outFormat);
        
    elseif procframes == false && parameters == true
        imageList_orig = dir(fullfile(outFolder_orig,outFormat));           % read saved frames
        while isempty(imageList_orig)
            inFormat_img = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
            for img_ext = 1:length(inFormat_img)
                imageList_orig = dir(fullfile(outFolder_orig,inFormat_img(img_ext)));
                if ~isempty(imageList_orig)
                    break
                end
            end
        end
        
        w = waitbar(1,'Loading frames','Name','Loading frames...');
        pause(1)
        fprintf('LOADING %s FRAMES ...\n',name)
        close(w)
    end
    
    %% Corrections & calculation of plume parameters
    if parameters == true
        imageList_proc = dir(fullfile(outFolder_proc,outFormat));           % read images
        if isempty(imageList_proc) && source == 'i'
            imageList_proc = dir(fullfile(outFolder_proc,inFormat));
        end
        outFolder_parameters = fullfile(outFolder,name);
        [imgplume_height,imgplume_width] = ...
            size(imread(fullfile(outFolder_proc,imageList_proc(1).name)));
        pixel.vent_pos_x = imgplume_width/2;
        pixel.vent_pos_y = imgplume_height/2;
        
        %% Corrections
        if gcal == 'c'
            geometrical_data = textscan(fopen(GeometricalData),...
                '%s %.f %.f %.1f %.1f %.f %.2f %s %s %.1f %.2f %.2f %.f');  % Read data as a table with columns with different format
            for V = 1:size(geometrical_data{1},1)
                if isequal(char(geometrical_data{1}(V)),name)
                    par.min_dist = geometrical_data{2}(V);                  % Minimum distance from the camera to the image plane
                    par.max_dist = geometrical_data{3}(V);                  % Maximum distance from the camera to the image plane
                    par.beta_h = geometrical_data{4}(V);                    % Horizontal FOV
                    par.beta_v = geometrical_data{5}(V);                    % Vertical FOV
                    par.phi = geometrical_data{6}(V);                       % Camera inclination
                    if wcor == true
                        par.omega = geometrical_data{7}(V);                 % Camera orientation
                        par.UTCdaytime = datetime(...                       % Day of the eruption (dd-Mmm-yyyy) and approximated to the hour time of the eruption (hh:00:00)
                            string(geometrical_data{8}(V))+' '+...
                            string(geometrical_data{9}(V)),...
                            'InputFormat','dd-MMM-yyyy HH:mm:ss');
                        par.wind_met = geometrical_data{10}(V);                 % Wind direction if known (otherwise set NaN in the column and use .nc files from ERA5)
                        par.vent_lat = geometrical_data{11}(V);             % Approximate latitude (decimal)
                        par.vent_long = geometrical_data{12}(V);            % Approximate longitude (decimal)
                        par.vent_h = geometrical_data{13}(V);               % Vent height
                    end
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

            if wcor == true
                wind_data = textscan(fopen(WindData),...
                    '%s %.1f %.1f %.f %.2f %s %s %.1f %.2f %.2f %.f');  % Read data as a table with columns with different format
                for V = 1:size(wind_data{1},1)
                    if isequal(char(wind_data{1}(V)),name)                 % Maximum distance from the camera to the image plane
                        par.beta_h = wind_data{2}(V);                    % Horizontal FOV
                        par.beta_v = wind_data{3}(V);                    % Vertical FOV
                        par.phi = wind_data{4}(V);                       % Camera inclination
                        par.omega = wind_data{5}(V);                 % Camera orientation
                        par.UTCdaytime = datetime(...                       % Day of the eruption (dd-Mmm-yyyy) and approximated to the hour time of the eruption (hh:00:00)
                            string(wind_data{6}(V))+' '+...
                            string(wind_data{7}(V)),...
                            'InputFormat','dd-MMM-yyyy HH:mm:ss');
                        par.wind_met = wind_data{8}(V);                 % Wind direction if known (otherwise set NaN in the column and use .nc files from ERA5)
                        par.vent_lat = wind_data{9}(V);             % Approximate latitude (decimal)
                        par.vent_long = wind_data{10}(V);            % Approximate longitude (decimal)
                        par.vent_h = wind_data{11}(V);               % Vent height
                    end
                end
                par.beta_h_pixel = par.beta_h/imgplume_width;               % Determine the horizontal angle subtended by each pixel
                par.beta_v_pixel = par.beta_v/imgplume_height;              % Determine the vertical angle subtended by each pixel
            end
        end

        [pixel,wdir] = calibration(gcal,wcor,procframes,outFolder_proc,...
            imageList_proc,imageList_orig,outFolder_parameters,...
            imgplume_height,imgplume_width,par,geopot_nc,wind_nc,pixel,name);

        %% Get & save plume parameters
        if wcor == false || isequal(wdir,'parallel')
            [height,width,plots,velocity,acceleration,tables] = ...
                plume_parameters(scale_fr,procframes,name,imageList_orig,...
                outFolder_proc,imageList_proc,outFolder_parameters,...
                imgplume_height,pixel);
        elseif wcor == true && not(isequal(wdir,'parallel'))
            [height,width,plots,velocity,acceleration,tables] = ...
                plume_parameters_w(scale_fr,procframes,name,outFolder_proc,...
                imageList_proc,outFolder_parameters,imgplume_height,pixel);
        end
        assignin("base","height",height)
        assignin("base","width",width)
        assignin("base","plots",plots)
        assignin("base","velocity",velocity)
        assignin("base","acceleration",acceleration)
        assignin("base","tables",tables)
        assignin("base","pixel",pixel)
        assignin("base","wdir",wdir)
    end
    beep
    if length(list) > 1 && isequal(isequal(length(list),v),0)
        close all
        clear pixel par
    end
end
warning('on','MATLAB:MKDIR:DirectoryExists')
end