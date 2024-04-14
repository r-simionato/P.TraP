%% manual_tracking - PlumeTraP
% Function to manually track plume height and calculate parameters
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> manual_tracking

function [height,velocity,acceleration,tables,pixel] = ...
    manual_tracking(scale_fr,name,outFolder_proc,...
    imageList_proc,outFolder_parameters,pixel)

%% Calculation of plume parameters
% Define structures of output data
height.mean = zeros(length(imageList_proc),1); 
height.error = height.mean;
height.error_tot = height.mean;

velocity.inst = zeros(length(imageList_proc),1); 
velocity.avg = velocity.inst; 
velocity.inst_error = velocity.inst; 
velocity.avg_error = velocity.inst;

acceleration.inst = zeros(length(imageList_proc),1); 
acceleration.avg = acceleration.inst; 
acceleration.inst_error = acceleration.inst; 
acceleration.avg_error = acceleration.inst;

time = zeros(length(imageList_proc),1);

for j = 1:length(imageList_proc)
    imgplume = imread(fullfile(outFolder_proc,imageList_proc(j).name)); % read images
    time(j) = (j-1)/scale_fr;

    figure(1)
    imshow(imgplume)
    title('Pick point for manual tracking')
    images.roi.Point(gca,'Position',[pixel.vent_pos_x,pixel.vent_pos_y],...
        'Color','r','MarkerSize',4,'LineWidth',0.25);
    h_pos = drawpoint('Color','b','MarkerSize',4,'LineWidth',0.25);
    col = round(h_pos.Position(1));
    row = round(h_pos.Position(2));

    % Height of the plume above the vent
    [height] = plumeheight(j,row,col,pixel,height);
    pixel.h_row(j) = row;
    pixel.h_col(j) = col;
    
    % Velocities of the plume head spreading in the atmosphere
    [velocity] = plumevelocity(j,time,pixel,height,velocity);
    
    % Accelerations of the plume head spreading in the atmosphere
    [acceleration] = plumeacceleration(j,time,velocity,acceleration);

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

%% Save parameters and graph
[tables] = savepar_man(outFolder_parameters,name,time,height,velocity,...
    acceleration);
fprintf('%s ANALYSED\n',name)
end