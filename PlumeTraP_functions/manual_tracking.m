%% manual_tracking - PlumeTraP
% Function to manually track plume height and calculate parameters
% Author: Riccardo Simionato. Date: May 2024
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
pixel.z_vent = repmat(pixel.z - pixel.z(pixel.vent_pos_y),1,1920);
nDigits = -(numel(num2str(round(max(pixel.z_vent,[],"all")))) - 2);
levels = sort([0 round(max(pixel.z_vent(:,pixel.vent_pos_x)),nDigits) ...
    :...
    -round((abs(round(max(pixel.z_vent(:,pixel.vent_pos_x)),nDigits))+ ...
    abs(round(min(pixel.z_vent(:,pixel.vent_pos_x)),nDigits)))/12,nDigits) ...
    :...
    round(min(pixel.z_vent(:,pixel.vent_pos_x)),nDigits)]);

for j = 1:length(imageList_proc)
    imgplume = imread(fullfile(outFolder_proc,imageList_proc(j).name)); % read images
    time(j) = (j-1)/scale_fr;

    figure(1)
    imshow(imgplume)
    hold on
    contour(pixel.z_vent,levels,"ShowText","on","LabelSpacing",1920);
    colormap(winter)
    hold off
    title('Pick point for manual tracking - Contour lines join points of equal elevation [m a.v.l.]')
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
            length(imageList_proc)),'Name','Plume manual tracking','Units',...
            'normalized','Position',[0.4,0.04,0.19,0.07]);
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume manual tracking','Units',...
            'normalized','Position',[0.4,0.04,0.19,0.07]);
    end
end
close(w)

fig = figure(2);
imshow(imgplume)
hold on
scatter(pixel.vent_pos_x,pixel.vent_pos_y,10,'red','filled');
if length(pixel.h_col) > 3
    scatter(pixel.h_col,pixel.h_row,10,height.mean,'filled')
else
    scatter([pixel.h_col,pixel.h_col],[pixel.h_row,pixel.h_row],10,[height.mean,height.mean],'filled')
end
while max(height.mean) > levels(end)
    levels = [levels levels(end)+(levels(end)-levels(end-1))];
end
[c,h] = contour(pixel.z_vent,levels,"EdgeAlpha",0.5);%,"ShowText","on","LabelSpacing",1920)
clabel(c,h,"LabelSpacing",1920,"FontSize",12);
colormap(winter)
hold off
title('Tracked height evolution')
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_trackedHeight.fig',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_trackedHeight.png',name)))

%% Save parameters and graph
[tables] = savepar_man(outFolder_parameters,name,time,height,velocity,...
    acceleration,pixel);
fprintf('%s ANALYSED\n',name)
end