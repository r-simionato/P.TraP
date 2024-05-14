%% manual_tracking_w - PlumeTraP
% Function to manually track plume height and calculate parameters with
% wind correction
% Author: Riccardo Simionato. Date: May 2024
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
pixel.z_wp_vent = pixel.z_wp - pixel.z_wp(pixel.vent_pos_y,pixel.vent_pos_x);
nDigits = -(numel(num2str(round(max(pixel.z_wp_vent(:,pixel.vent_pos_x))))) - 2);
levels = sort([0 round(max(pixel.z_wp_vent(:,pixel.vent_pos_x)),nDigits) ...
    :...
    -round((abs(round(max(pixel.z_wp_vent(:,pixel.vent_pos_x)),nDigits))+ ...
    abs(round(min(pixel.z_wp_vent(:,pixel.vent_pos_x)),nDigits)))/12,nDigits) ...
    :...
    round(min(pixel.z_wp_vent(:,pixel.vent_pos_x)),nDigits)]);

% prompt = {'Set vertical isolines array:'}; dlgtitle = 'Set vertical isolines'; dims = [1 60]; definput = {'0 0'}; iso_out = inputdlg(prompt,dlgtitle,dims,definput); iso = sscanf(iso_out{1},'%f');

for j = 1:length(imageList_proc)
    imgplume = imread(fullfile(outFolder_proc,imageList_proc(j).name)); % read images
    time(j) = (j-1)/scale_fr;

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

    f1 = figure(1);
    imshow(imgplume)
    hold on
    [c,h] = contour(pixel.z_wp_vent,levels);%,"ShowText","on","LabelSpacing",1920)
    clabel(c,h,"LabelSpacing",1920,"FontSize",12);
% [c,h] = contour(pixel.z_wp_vent,[0 500 1000 1500 2000 2500 3000 3500],"LineWidth",1.75); clabel(c,h,"LabelSpacing",1920,"FontName","Myriad Pro",'FontWeight','bold',"FontSize",20); [C,H] = contour(pixel.z_wp_vent,[-1000 -500],"LineWidth",1.75); clabel(C,H,"LabelSpacing",1920,"FontName","Myriad Pro",'FontWeight','bold',"FontSize",20,"Color","w");
% [Cd,Hd] = contour(pixel.dist_vent,iso.',"LineWidth",1.75); clabel(Cd,Hd,"LabelSpacing",1080,"FontName","Myriad Pro",'FontWeight','bold',"FontSize",20);
    colormap(winter)
    hold off
    title('Pick point for manual tracking - Contour lines join points of equal elevation [m a.v.l.]')
    images.roi.Point(gca,'Position',[pixel.vent_pos_x,pixel.vent_pos_y],...
        'Color','r','MarkerSize',4,'LineWidth',0.25);
    h_pos = drawpoint('Color','b','MarkerSize',4,'LineWidth',0.25);
    col = round(h_pos.Position(1));
    row = round(h_pos.Position(2));
    % Comment lines 54-80 and uncomment 82-85 to use already saved row and col values:
    % n = "C:\Users\simionat\OneDrive - unige.ch\Documenti\Sakurajima23\SelectedPlumes\SAK4\SAK4g_P_231114-0730\SAK4g_P_231114-0730_wp_parameters.csv"
    % rowcol = table2array(readtable(n));
    % row = rowcol(j,2);
    % col = rowcol(j,3);

    % Height of the plume above the vent
    [height] = plumeheight_man_w(j,row,col,pixel,height);
    pixel.h_row(j) = row;
    pixel.h_col(j) = col;
    
    % Velocities of the plume head spreading in the atmosphere
    [velocity] = plumevelocity_w(j,time,pixel,height,velocity);
    
    % Accelerations of the plume head spreading in the atmosphere
    [acceleration] = plumeacceleration_w(j,time,velocity,acceleration);
end
close(w)
close(f1)

fig = figure(2);
imshow(imgplume)
hold on
scatter(pixel.vent_pos_x,pixel.vent_pos_y,10,'red','filled');
if length(pixel.h_col) > 3
    scatter(pixel.h_col,pixel.h_row,10,height.wp_mean,'filled')
else
    scatter([pixel.h_col,pixel.h_col],[pixel.h_row,pixel.h_row],10,[height.wp_mean,height.wp_mean],'filled')
end
while max(height.wp_mean) > levels(end)
    levels = [levels levels(end)+(levels(end)-levels(end-1))];
end
[c,h] = contour(pixel.z_wp_vent,levels,"EdgeAlpha",0.5);%,"ShowText","on","LabelSpacing",1920)
clabel(c,h,"LabelSpacing",1920,"FontSize",12);
colormap(winter)
hold off
title('Tracked height evolution')
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_trackedHeight.fig',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_trackedHeight.png',name)))

%% Save parameters into an excel sheet
[tables] = savepar_man_w(outFolder_parameters,name,time,height,velocity,...
    acceleration,pixel);
fprintf('%s ANALYSED\n',name)
end