%% plumeheight_man_w - PlumeTraP
% Function to calculate the physical height of a plume with manual tracking
% and wind correction
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> manual_tracking_w --> plumeheight_man_w

function [height] = plumeheight_man_w(j,row,col,pixel,height)

if isempty(row) && isempty(col)
    height.mean(j) = 0;
    height.error_ref(j) = pixel.z_err(pixel.vent_pos_y)-pixel.z_err(pixel.vent_pos_y);
    height.error(j) = pixel.z_err(pixel.vent_pos_y);
    height.wp_mean(j) = 0;
    height.wp_error_ref(j) = pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x)-...
        pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x);
    height.wp_error(j) = pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x);
    
else
    % Calculation in the image plane (without wind correction)
    height.mean(j) = pixel.z(min(row))-pixel.z(pixel.vent_pos_y); % Mean height of the top of the plume
    height.error_ref(j) = pixel.z_err(min(row))-pixel.z_err(pixel.vent_pos_y); % Mean half the referenced error (only depending on pixel, not on camera - image plane distance)
    height.error(j) = pixel.z_err(min(row)); % Mean half the total error (e.g., height.mean +- height.error)

    % Calculation in the wind-corrected plane
    height.wp_mean(j) = (pixel.z_wp(row,col)-...
        pixel.z_wp(pixel.vent_pos_y,pixel.vent_pos_x)); % Mean height
    height.wp_error_ref(j) = (pixel.z_wp_err(row,col)-...
        pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x)); % Half the total error
    height.wp_error(j) = pixel.z_wp_err(row,col);
end
end