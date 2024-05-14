%% plume_parameters_app - PlumeTraP
% Function to show and save parameters from binary images with vent 
% position picked in GUI
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> plume_parameters_app

function [height,width,plots,velocity,acceleration,tables] = ...
    plume_parameters_app(scale_fr,procframes,name,outFolder_proc,...
    imageList_proc,outFolder_parameters,imgplume_height,pixel)

%% Calculation of plume parameters
% Define structures of output data
height.mean = zeros(length(imageList_proc),1); 
height.error = height.mean;
height.error_ref = height.mean;

width.max = zeros(length(imageList_proc),1); 
width.max_error = width.max;
width.rows = zeros(imgplume_height,length(imageList_proc)); 
width.rows_error = width.rows;

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
    imgplume = ...
        logical(imread(fullfile(outFolder_proc,imageList_proc(j).name))); % read images as logical
    [row,col] = find(imgplume); % find rows and columns where imgplume==1
    time(j) = (j-1)/scale_fr;
    
    % Height of the plume above the vent
    [height] = plumeheight(j,row,col,pixel,height);
    
    % Total and maximum width of the plume
    [width,plots] = plumewidth(j,imgplume,imgplume_height,row,col,...
    pixel,width);
    
    % Velocities of the plume head spreading in the atmosphere
    [velocity] = plumevelocity(j,time,pixel,height,velocity);
    
    % Accelerations of the plume head spreading in the atmosphere
    [acceleration] = plumeacceleration(j,time,velocity,acceleration);
    
    %% Progress and plots
    % Show progress of the analysis
    progress = j/length(imageList_proc);
    if j == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume analysis','Units',...
            'normalized','Position',[0.4,0.04,0.19,0.07]);
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name','Plume analysis','Units',...
            'normalized','Position',[0.4,0.04,0.19,0.07]);
    end
    
    % Show plots
    if procframes == true
        figure(3)
        fig = figure(3);
    else
        figure(1)
        fig = figure(1);
    end
    fig.Units = 'normalized';
    fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
    % Plot height vs time
    subplot(2,2,1)
    plot(time(j),height.mean(j),'r.','MarkerSize',6)
    title('Plume height vs time')
    xlabel('Time [s]')
    ylabel('Plume height [m]')
    hold on
    % Plot height vs width
    subplot(2,2,2)
    plot(plots.width,plots.height,'r.','MarkerSize',6)
    title('Plume height vs width')
    xlabel('Plume width [m]')
    ylabel('Plume height [m]')
    % Plot max width vs time
    subplot(2,2,3)
    plot(time(j),width.max(j),'r.','MarkerSize',6)
    title('Plume width vs time')
    xlabel('Time [s]')
    ylabel('Plume width [m]')
    hold on
    % Plot velocity and acceleration
    subplot(2,2,4)
    yyaxis left
    p1 = plot(time(j),velocity.avg(j),'r.','MarkerSize',6);
    xlabel('Time [s]')
    ylabel('Velocity [m/s]')
    hold on
    yyaxis right
    p2 = plot(time(j),acceleration.avg(j),'b.','MarkerSize',6);
    ylabel('Acceleration [m/s^2]')
    hold off
    ax = gca;
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = 'k';
    title('Plume velocity / acceleration vs time')
    legend([p1, p2],{'Velocity','Acceleration'},'Location','best','FontSize',6)
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

%% Save parameters and graph
[tables] = savepar(outFolder_parameters,name,time,height,width,velocity,...
    acceleration,plots,procframes);
fprintf('%s ANALYSED\n',name)
end