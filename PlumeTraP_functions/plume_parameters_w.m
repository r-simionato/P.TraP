%% plume_parameters_w - PlumeTraP
% Function to show and save parameters from binary images with
% wind correction
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> plume_parameters_w

function [height,width,plots,velocity,acceleration,tables]=...
    plume_parameters_w(scale_fr,procframes,name,outFolder_proc,...
    imageList_proc,outFolder_parameters,imgplume_height,pixel)

%% Calculation of plume parameters
% Define structures of output data
height.mean = zeros(length(imageList_proc),1); 
height.error = height.mean;
height.wp_mean = height.mean; 
height.wp_error = height.mean;

width.max = zeros(length(imageList_proc),1); 
width.max_error = width.max;
width.rows = zeros(imgplume_height,length(imageList_proc)); 
width.rows_error = width.rows;
width.wp_max = width.max; 
width.wp_max_error = width.max;
width.wp_rows = width.rows; 
width.wp_rows_error = width.rows;

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
plots.wp_height_tab = zeros(imgplume_height,length(imageList_proc));
plots.wp_height_err_tab = plots.wp_height_tab;

for j = 1:length(imageList_proc)
    imgplume = ...
        logical(imread(fullfile(outFolder_proc,imageList_proc(j).name))); % read images as logical
    [row,col] = find(imgplume);
    time(j) = (j-1)/scale_fr;
    
    % Height of the plume above the vent
    [height,plots] = plumeheight_w(j,imgplume,row,col,pixel,height,plots);
    
    % Total and maximum width of the plume
    [width,plots] = plumewidth_w(imgplume_height,j,imgplume,row,col,pixel,...
        width,plots);
    
    % Velocities of the plume head spreading in the atmosphere
    [velocity] = plumevelocity_w(j,time,pixel,height,velocity);
    
    % Accelerations of the plume head spreading in the atmosphere
    [acceleration] = plumeacceleration_w(j,time,velocity,acceleration);
    
    %% Progress and plots
    % Show progress of the analysis
    progress = j/length(imageList_proc);
    if j == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume analysis');
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume analysis');
    end

    % Show plots
    if procframes == true
        figure(4)
        fig = figure(4);
    else
        figure(2)
        fig = figure(2);
    end
    fig.Units = 'normalized';
    fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
    % Plot height vs time
    subplot(2,2,1)
    plot(time(j),height.wp_mean(j),'k.','MarkerSize',6)
    hold on
    h_ip = plot(time(j),height.mean(j),'.','MarkerSize',6);
    h_ip.Color = [0.7490 0.7490 0.7490];
    hold off
    title('Plume height vs time')
    xlabel('Time [s]')
    ylabel('Plume height [m]')
    legend({'wind-corrected','image plane'},'Location','northwest',...
        'FontSize',6)
    hold on
    % Plot height vs width
    subplot(2,2,2)
    plot(plots.wp_width,plots.wp_height_plot,'k.','MarkerSize',6)
    hold on
    plot(plots.width,plots.height,'.','MarkerSize',6,'Color',[0.7490 0.7490 0.7490])
    hold off
    title('Plume height vs width')
    xlabel('Plume width [m]')
    ylabel('Plume height [m]')
    legend({'wind-corrected','image plane'},'Location','northeast',...
        'FontSize',6)
    % Plot max width vs time
    subplot(2,2,3)
    plot(time(j),width.wp_max(j),'k.','MarkerSize',6)
    hold on
    wm_ip = plot(time(j),width.max(j),'.','MarkerSize',6);
    wm_ip.Color = [0.7490 0.7490 0.7490];
    hold off
    title('Plume width vs time')
    xlabel('Time [s]')
    ylabel('Plume width [m]')
    legend({'wind-corrected','image plane'},'Location','northwest',...
        'FontSize',6)
    hold on
    % Plot velocity
    subplot(2,2,4)
    yyaxis left
    v_wp = plot(time(j),velocity.wp_avg(j),'.','MarkerSize',6);
    v_wp.Color = [0.6350 0.0780 0.1840];
    xlabel('Time [s]')
    ylabel('Velocity [m/s]')
    hold on
    v_ip = plot(time(j),velocity.avg(j),'.','MarkerSize',6);
    v_ip.Color = [0.9490 0.5882 0.6588];
    yyaxis right
    a_wp = plot(time(j),acceleration.wp_avg(j),'.','MarkerSize',6);
    a_wp.Color = [0.0000 0.4470 0.7410];
    a_ip = plot(time(j),acceleration.avg(j),'.','MarkerSize',6);
    a_ip.Color = [0.6549 0.8275 1.0000];
    ylabel('Acceleration [m/s^2]')
    hold off
    ax = gca;
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = 'k';
    title('Plume velocity / acceleration vs time')
    legend([v_wp,v_ip,a_wp,a_ip],{'Velocity (wind-corrected)',...
        'Velocity (image plane)','Acceleration (wind-corrected)',...
        'Acceleration (image plane)'},'Location','northeast','FontSize',6)
    hold on
    % Save .gif file
    plot_frame = getframe(fig);
    plot_image = frame2im(plot_frame);
    [A,map] = rgb2ind(plot_image,256);
    if j == 1 % save first frame of the .gif
        imwrite(A,map,...
            fullfile(outFolder_parameters,sprintf('%s_Plot.gif',name)),...
            'gif','Loopcount',inf);
    else % add subsequent frames
        imwrite(A,map,...
            fullfile(outFolder_parameters,sprintf('%s_Plot.gif',name)),...
            'gif','WriteMode','append');
    end
end
close(w)
hold off

%% Save parameters into an excel sheet
[tables] = savepar_w(outFolder_parameters,name,time,height,width,velocity,...
    acceleration,plots,procframes);
fprintf('%s ANALYSED\n',name)
end