%% plumeheight - PlumeTraP
% Function to calculate the physical height of a plume from a binary image
% Author: Riccardo Simionato. Date: March 2022
% Structure: PlumeTrAP --> plume_parameters --> plumeheight

function [height] = plumeheight(j,row,col,pixel,height)

if isempty(row) && isempty(col)
    height.mean(j) = 0;
    
else
    height.mean(j) = pixel.z(min(row))-pixel.z(pixel.vent_pos_y); % Mean height of the top of the plume
    height.error(j) = pixel.z_err(min(row))+pixel.z_err(pixel.vent_pos_y); % Half the total error (e.g., height.mean +- height.error)
end    
end