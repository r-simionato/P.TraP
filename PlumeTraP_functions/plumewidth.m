%% plumewidth - PlumeTraP
% Function to calculate the physical width of a plume from a binary image
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> plume_parameters     --> plumewidth
%            PlumeTraP --> plume_parameters_app --> plumewidth

function [width,plots] = plumewidth(j,imgplume,imgplume_height,row,col,...
    pixel,width)

if isempty(row) && isempty(col)
    width.max(j) = 0;
    plots.width = 0;  
    plots.height = 0;

else
    left_px = zeros(imgplume_height,1);
    right_px = left_px;
    width_rows = left_px;
    width_rows_err = left_px;
    
    for w=min(row):max(row)
        left_px(w) = find(imgplume(w,:),1,'first'); % Crate array of the first plume pixel from left position for each row
        right_px(w) = find(imgplume(w,:),1,'last'); % Crate array of the last plume pixel from left position for each row
        
        width_rows(w) = pixel.x(right_px(w))-pixel.x(left_px(w)); % Width of each row
        width_rows_err(w) = pixel.x_err(right_px(w))-pixel.x_err(left_px(w)); % Mean half error of the width of each row
    end
    
    plots.width = width_rows(width_rows ~= 0); % delete zero values to plot the width of each row vs height
    plots.height_tab = pixel.z-pixel.z(pixel.vent_pos_y); % get height for the plot and consider only plume height (not whole image)
    plots.height_tab(~width_rows) = 0; % apply a mask
    plots.height_error_tab = pixel.z_err;
    plots.height_error_tab(~width_rows) = 0;
    plots.height = plots.height_tab(width_rows ~= 0); % delete zero values
    
    width.rows(:,j) = width_rows; % save multiple width in different columns
    width.rows_error(:,j) = width_rows_err;
    [width.max(j),pos] = max(width_rows); % Find the maximum value for this timestep and its position
    width.max_error(j) = width_rows_err(pos);
end

end