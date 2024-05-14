%% windERA5 - PlumeTraP
% Function to calculate the wind from ECMWF ERA5 data
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> calibration --> windERA5
%            PlumeTraP --> calibration_app --> windERA5

function [par,windplot] = windERA5(outFolder_proc,imageList_proc,geopot_nc, ...
    wind_nc,roiPos,par,pixel)

time = ncread(geopot_nc,'time');
long = ncread(geopot_nc,'longitude'); % Read the parameters in MatLab
lat = ncread(geopot_nc,'latitude');
geopot = ncread(geopot_nc,'z');
t = datetime(1900,1,1,time,0,0); % Convert hours since 1900-01-01 00:00:00.0 into a dd-Mmm-yyyy hh:00:00 format
[row_t] = find(t == par.UTCdaytime); % Select time in the 4D matrix
[row_lat] = find(lat == par.vent_lat); % Select latitude in the 4D matrix
[row_long] = find(long == par.vent_long); % Select longitude in the 4D matrix
geopot_sealevel = geopot(row_long,row_lat,:,row_t);
height_sealevel = reshape(geopot_sealevel/9.80665,...
    [length(geopot_sealevel),1]);

u_comp = ncread(wind_nc,'u');
v_comp = ncread(wind_nc,'v'); % Read the parameters in MatLab
u_comp = u_comp(row_long,row_lat,:,row_t);
v_comp = v_comp(row_long,row_lat,:,row_t); % m/s

wind_dir = zeros(length(height_sealevel),1);
wind_dir_met = wind_dir;
N_comp = wind_dir;
E_comp = wind_dir;
for d = 1:length(height_sealevel) % Calculate the wind direction basing on the northward and eastward velocity components (our wind direction here is not the conventional, but the direction towards where the wind blows)
    wind_dir_met(d) = mod(180 + 180/pi * atan2(u_comp(d),v_comp(d)), 360); % conventional meteorological wind direction
    if u_comp(d) >= 0
        wind_dir(d) = 90-atand(v_comp(d)/u_comp(d)); % direction towards the wind is blowing
    elseif u_comp(d) < 0
        wind_dir(d) = 270-atand(v_comp(d)/u_comp(d)); % direction towards the wind is blowing
    end
    N_comp(d) = v_comp(d);
    E_comp(d) = u_comp(d);
end

height_ventlevel = height_sealevel-par.vent_h; % Subtract the vent height to the wind heights matrix
height_ventlevel = height_ventlevel(height_ventlevel >= 0); % Delete height values lower than zero
for r_low = length(wind_dir):-1:length(height_ventlevel)+1 % Delete rows corresponding to negative height
    wind_dir(r_low,:) = [];
    wind_dir_met(r_low,:) = [];
    N_comp(r_low,:) = [];
    E_comp(r_low,:) = [];
end
height_ventlevel_lower = height_ventlevel(end);
wind_dir_lower = wind_dir(end);

imgplume_last = logical(imread(fullfile(outFolder_proc,...
    imageList_proc(length(imageList_proc)).name))); % read last image as logical to get maximum height
[row,~] = find(imgplume_last);
if min(row) == 1
    row = roiPos(2);
end
height_max = pixel.z(min(row))-pixel.z(pixel.vent_pos_y); % plume maximum height
heightoutofrange = height_ventlevel(height_ventlevel >= height_max); % Create a matrix of height out of maximum plume height range
for r_high = length(heightoutofrange)-1:-1:1 % Delete rows corresponding to heights out of range
    height_ventlevel(r_high,:) = [];
    wind_dir(r_high,:) = [];
    wind_dir_met(r_high,:) = [];
    N_comp(r_high,:) = [];
    E_comp(r_high,:) = [];
end

% Get the average wind direction
if isempty(wind_dir)
    height_ventlevel = height_ventlevel_lower;
    par.wind_met = mod(wind_dir_lower+180,360);
    par.wind = wind_dir_lower;
else
    N_comp_mean = mean(N_comp);
    E_comp_mean = mean(E_comp);
    % Conventional meteorological wind direction
    par.wind_met = mod(180 + 180/pi * atan2(E_comp_mean,N_comp_mean), 360); 
    % Direction towards the wind is blowing
    if E_comp_mean >= 0
        par.wind = 90-atand(N_comp_mean/E_comp_mean);
    elseif E_comp_mean < 0
        par.wind = 270-atand(N_comp_mean/E_comp_mean);
    end
end
windplot.wind = wind_dir;
windplot.wind_met = wind_dir_met;
windplot.h_vent = height_ventlevel;

end