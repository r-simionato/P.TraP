%% manual_tracking_w - PlumeTraP
% Function to manually track plume height and calculate parameters with
% wind correction
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> manual_tracking_w

function [height,velocity,acceleration,tables,pixel] = ...
    manual_tracking_w(scale_fr,name,outFolder_proc,...
    imageList_proc,outFolder_parameters,pixel)

%% Calculation of plume parameters
% Define structures of output data
height.mean = zeros(length(imageList_proc),1); 
height.error = height.mean;
height.error_tot = height.mean;
height.wp_mean = height.mean; 
height.wp_error = height.mean;
height.wp_error_tot = height.mean;

velocity.inst = zeros(length(imageList_proc),1); 
velocity.avg = velocity.inst; 
velocity.inst_error = velocity.inst; 
velocity.avg_error = velocity.inst;
velocity.wp_inst = velocity.inst; 
velocity.wp_avg = velocity.inst; 
velocity.wp_inst_error = velocity.inst; 
velocity.wp_avg_error = velocity.inst;

acceleration.inst = zeros(length(imageList_proc),1); 
acceleration.avg = acceleration.inst; 
acceleration.inst_error = acceleration.inst; 
acceleration.avg_error = acceleration.inst;
acceleration.wp_inst = acceleration.inst; 
acceleration.wp_avg = acceleration.inst; 
acceleration.wp_inst_error = acceleration.inst; 
acceleration.wp_avg_error = acceleration.inst;

time = zeros(length(imageList_proc),1);

for j = 1:length(imageList_proc)
    imgplume = imread(fullfile(outFolder_proc,imageList_proc(j).name)); % read images
    time(j) = (j-1)/scale_fr;

    figure(1)
    imshow(imgplume)
    hold on
    contour(pixel.z_wp,10)
    colormap(winter)
    hold off
    title('Pick point for manual tracking (contour lines join points of equal elevation)')
    images.roi.Point(gca,'Position',[pixel.vent_pos_x,pixel.vent_pos_y],...
        'Color','r','MarkerSize',4,'LineWidth',0.25);
    h_pos = drawpoint('Color','b','MarkerSize',4,'LineWidth',0.25);
    col = round(h_pos.Position(1));
    row = round(h_pos.Position(2));

    % Height of the plume above the vent
    [height] = plumeheight_man_w(j,row,col,pixel,height);
    pixel.h_row(j) = row;
    pixel.h_col(j) = col;
    
    % Velocities of the plume head spreading in the atmosphere
    [velocity] = plumevelocity_w(j,time,pixel,height,velocity);
    
    % Accelerations of the plume head spreading in the atmosphere
    [acceleration] = plumeacceleration_w(j,time,velocity,acceleration);
    
    % Show progress of the analysis
    progress = j/length(imageList_proc);
    if j == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume analysis');
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume analysis');
    end
end
close(w)

fig = figure(2);
imshow(imgplume)
axis on
hold on
scatter(pixel.h_col,pixel.h_row,10,pixel.h_col,'filled')
colormap(flip(winter))
title('Tracked height evolution')
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_trackedHeight.png',name)))

%% Save parameters into an excel sheet
[tables] = savepar_man_w(outFolder_parameters,name,time,height,velocity,...
    acceleration);
fprintf('%s ANALYSED\n',name)
end