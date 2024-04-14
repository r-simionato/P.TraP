%% plumeheight - PlumeTraP
% Function to calculate the physical height of a plume
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> plume_parameters     --> plumeheight
%            PlumeTraP --> plume_parameters_app --> plumeheight
%            PlumeTraP --> manual_tracking      --> plumeheight

function [height] = plumeheight(j,row,col,pixel,height)

if isempty(row) && isempty(col)
    height.mean(j) = 0;
    height.error_tot(j) = pixel.z_err(pixel.vent_pos_y);
    height.error(j) = pixel.z_err(pixel.vent_pos_y)-pixel.z_err(pixel.vent_pos_y);
else
    height.mean(j) = pixel.z(min(row))-pixel.z(pixel.vent_pos_y); % Mean height of the top of the plume
    height.error_tot(j) = pixel.z_err(min(row)); % Mean half the total error (e.g., height.mean +- height.error)
    height.error(j) = pixel.z_err(min(row))-pixel.z_err(pixel.vent_pos_y); % Mean half the referenced error (only depending on pixel, not on camera - image plane distance)
end

end