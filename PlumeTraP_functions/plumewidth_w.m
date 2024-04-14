%% plumewidth_w - PlumeTraP
% Function to calculate the physical width of a plume with wind correction
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> plume_parameters_w --> plumewidth_w

function [width,plots] = plumewidth_w(imgplume_height,j,imgplume,row,col,...
    pixel,width,plots)

if isempty(row) && isempty(col)
    width.max(j) = 0;
    plots.width = 0;
    plots.height = 0;

    width.max(j) = 0;
    plots.wp_width = 0;
    plots.wp_height = 0;
else
    %% Calculation in the image plane (without wind correction)
    left_px = zeros(imgplume_height,1);
    right_px = left_px;
    width_rows = left_px;
    width_rows_err = left_px;

    for w=min(row):max(row)
        left_px(w) = find(imgplume(w,:),1,'first'); % Crate array of the first plume pixel from left position for each row
        right_px(w) = find(imgplume(w,:),1,'last'); % Crate array of the last plume pixel from left position for each row

        width_rows(w) = pixel.x(right_px(w))-pixel.x(left_px(w)); % Width of each row
        width_rows_err(w) = pixel.x_err(right_px(w))-pixel.x_err(left_px(w)); % Half error of the width of each row
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

    %% Calculation in the wind-corrected plane
    firstvalue_img = zeros(imgplume_height,1);
    lastvalue_img = firstvalue_img;
    firstcol_img = firstvalue_img;
    lastcol_img = firstvalue_img;

    plumeshape_height = pixel.z_wp;
    plumeshape_height(~imgplume) = 0;
    for h = 1:imgplume_height
        if isempty(find(plumeshape_height(h,:),1,'first'))
            firstvalue_img(h) = 0;
            lastvalue_img(h) = 0;
            lastcol_img(h) = 0;
            firstcol_img(h) = 0;
        else
            firstvalue_img(h) = plumeshape_height(h,...
                find(plumeshape_height(h,:),1,'first')); % Crate array with height of the first plume pixel from left
            lastvalue_img(h) = plumeshape_height(h,...
                find(plumeshape_height(h,:),1,'last')); % Crate array with height of the last plume pixel from left
            firstcol_img(h) = find(plumeshape_height(h,:),1,'first'); % Crate array with col value of the first plume pixel from left
            lastcol_img(h) = find(plumeshape_height(h,:),1,'last'); % Crate array with col value of the last plume pixel from left
        end
    end
    firstvalue_plume = firstvalue_img(firstvalue_img ~= 0);
    lastvalue_plume = lastvalue_img(lastvalue_img ~= 0); % Remove zero values
    lastcol_plume = lastcol_img(lastcol_img ~= 0);
    firstcol_plume = firstcol_img(firstcol_img ~= 0);

    plots.wp_width = zeros(imgplume_height,1);
    plots.wp_width_err = plots.wp_width;
    for r = 1:length(firstvalue_plume)
        lastvalue_plume_scaled = abs(firstvalue_plume(r)-lastvalue_plume); % Create array of difference values
        value_delta = min(lastvalue_plume_scaled,[],'all'); % Select the minimum difference value
        [row_last_iso,~] = ...
            find(lastvalue_plume_scaled == value_delta); % Find position of the minimum difference value

        plots.wp_width(r) = sqrt((pixel.x_wp(lastcol_plume(row_last_iso))-...
            pixel.x_wp(firstcol_plume(r)))^2+...
            (pixel.y_wp(lastcol_plume(row_last_iso))-...
            pixel.y_wp(firstcol_plume(r)))^2); % Mean width; use the two column value to calculate the width in the proper vectors to get euclidean distance
        plots.wp_width_err(r) = sqrt((pixel.x_wp_err(lastcol_plume(row_last_iso))-...
            pixel.x_wp_err(firstcol_plume(r)))^2+...
            (pixel.y_wp_err(lastcol_plume(row_last_iso))-...
            pixel.y_wp_err(firstcol_plume(r)))^2); % Half the total error
    end
    width.wp_rows(:,j) = plots.wp_width; % Save width of each row per each frame in different columns
    width.wp_rows_error(:,j) = plots.wp_width_err;
    width.wp_max(j) = max(plots.wp_width); % Find the maximum value for this frame
    [rowWmax,~] = find(plots.wp_width == width.wp_max(j)); % Find position of the maximum value
    width.wp_max_error(j) = max(plots.wp_width_err(rowWmax)); % Find the error related to the maximum width
    plots.wp_width = plots.wp_width(1:length(plots.wp_height_plot)); % Obtain a vector of the height vector dimensions to plot them
end
end