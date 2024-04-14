%% plumeheight_w - PlumeTraP
% Function to calculate the physical height of a plume with wind correction
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> plume_parameters_w --> plumeheight_w

function [height,plots] = plumeheight_w(j,imgplume,row,col,pixel,height,...
    plots)

if isempty(row) && isempty(col)
    height.mean(j) = 0;
    height.error_tot(j) = pixel.z_err(pixel.vent_pos_y);
    height.error(j) = pixel.z_err(pixel.vent_pos_y)-pixel.z_err(pixel.vent_pos_y);
    height.wp_mean(j) = 0;
    height.wp_error_tot(j) = pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x);
    height.wp_error(j) = pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x)-...
        pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x);
    plots.wp_height = 0;
    plots.wp_height_plot = 0;
    plots.wp_height_err = 0;
    
else
    % Calculation in the image plane (without wind correction)
    height.mean(j) = pixel.z(min(row))-pixel.z(pixel.vent_pos_y); % Mean height of the top of the plume
    height.error_tot(j) = pixel.z_err(min(row)); % Mean half the total error (e.g., height.mean +- height.error)
    height.error(j) = pixel.z_err(min(row))-pixel.z_err(pixel.vent_pos_y); % Mean half the referenced error (only depending on pixel, not on camera - image plane distance)

    % Calculation in the wind-corrected plane
    plumeshape_height = pixel.z_wp; 
    plumeshape_height_nan = pixel.z_wp;
    plumeshape_height(~imgplume) = 0;
    plumeshape_height_nan(plumeshape_height == 0) = NaN;
    [rowMax,colMax] = ...
        find(plumeshape_height_nan == max(plumeshape_height_nan,[],'all')); % Find position of the maximum value in a NaN and values matrix
    [rowMin,~] = ...
        find(plumeshape_height_nan == min(plumeshape_height_nan,[],'all')); % Find position of the minimum value in a NaN and values matrix (otherwise the min is 0 and it is in more than one cell)
    
    height.wp_mean(j) = (pixel.z_wp(rowMax,colMax)-...
        pixel.z_wp(pixel.vent_pos_y,pixel.vent_pos_x)); % Mean height
    height.wp_error_tot(j) = pixel.z_wp_err(rowMax,colMax);
    height.wp_error(j) = (pixel.z_wp_err(rowMax,colMax)-...
        pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x)); % Half the total error

    plots.wp_height_plot = 0;
    plots.wp_height_err = 0;
    plots.wp_height_plot = pixel.z_wp(rowMax:rowMin,colMax)-... % Get height to compare with width in each row
        pixel.z_wp(pixel.vent_pos_y,pixel.vent_pos_x); 
    plots.wp_height_err = pixel.z_wp_err(rowMax:rowMin,colMax)-...
        pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x);
    plots.wp_height = plots.wp_height_plot;
    for l = length(rowMax:rowMin)+1:1080 % Fill with zeros up to the 1080th column
        plots.wp_height(l) = 0;
        plots.wp_height_err(l) = 0;
    end
    plots.wp_height_tab(:,j) = plots.wp_height; % Save height of each row per each frame in different columns
    plots.wp_height_err_tab(:,j) = plots.wp_height_err;
end
end