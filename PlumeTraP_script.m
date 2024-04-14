%% PlumeTraP 2.0.0 - Script version - %%
% Detection and parameterization of volcanic plumes in visible videos.
% Starting from a video, frames are saved, segmentated through a specific 
% technique and basilar parameters of the plume through time are extracted.

% Copyright (C) 2024 Riccardo Simionato
% Last updated: Apr-2024
% Developed with MATLAB R2018b and Image Processing Toolbox 10.3
% Tested up to MATLAB R2023b and Image Processing Toolbox 23.2

% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details 
% (https://www.gnu.org/licenses/gpl-3.0.html).

clc; clearvars; close all;

%% Select if source is videos ('v') or time series of images ('i') 
source = 'v';

% Path of folder containing video(s) (if videos, possible to process multiple videos in loop) or images
inFolder = 'C:\PlumeTraP\Videos\';
% File format (video or images)
inFormat = '*.mp4';
% If the input is images, specify the name for the output files
name = '';

% Select the main output folder and the output file format for the images (PNG is recommended)
outFolder = 'C:\PlumeTraP\Outputs\';
outFormat = '*.png';

%% Parts of the algorithm to be run (true to run, false to skip)
% Save n frames per second (false only if frames are already saved)
saveframes = false;
% Apply image processing to the frames (false only if processed frames are already saved)
procframes = true;
% Extract parameters from the images
parameters = true;
% Set scale factor to save/analyse n frames per second (e.g. if scale_fr=2 --> 2 frames/s are saved)
scale_fr = 1;

%% Geometrical calibration
% 'c' to calibrate basing on geometrical data, 'u' to upload calibrated data 
gcal = 'c';

% If gcal == 'c', insert path of the file to calibrate basing on geometrical data (.txt or .csv file)
GeometricalData = 'C:\PlumeTraP\Videos\calibration_parameters_windcorr.txt';

% If gcal == 'u', insert path of the file containing the calibrated data (.txt or .csv file)
HorizontalCalibratedData = 'C:\PlumeTraP\Videos\calibrated_h_data.txt';
VerticalCalibratedData = 'C:\PlumeTraP\Videos\calibrated_v_data.txt';

%% Wind calibration (true to run, false to skip)
wcor = true;

% If wcor == true, insert path of the .nc files (ERA5 hourly data on pressure levels) for the wind correction
geopot_nc = 'C:\PlumeTraP\Videos\geopot.nc';   % File containing the geopotential data
wind_nc = 'C:\PlumeTraP\Videos\wind.nc';       % File containing the wind velocity data
% SET geopot_nc=nan AND wind_nc=nan IF WIND DIRECTION IS KNOWN (to be specified in the GeometricalData file); 
% if single file use the same path for both geopot_nc wind_nc

% If wcor == true and gcal == 'u', insert path of the file to correct basing on geometrical data (.txt or .csv file)
WindData = 'C:\PlumeTraP\Videos\calibration_parameters_windonly.txt';

%% %%%%%%%%%%% Start PlumeTraP (do not modify anything here) %%%%%%%%%%% %%
PlumeTraP_main4script...
    (source,inFolder,name,inFormat,outFolder,outFormat,...
    saveframes,procframes,parameters,scale_fr,...
    gcal,GeometricalData,HorizontalCalibratedData,VerticalCalibratedData,...
    wcor,geopot_nc,wind_nc,WindData);
