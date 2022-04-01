%% plume_parameters - PlumeTraP
% Function to show and save parameters from binary images
% Author: Riccardo Simionato. Date: March 2022
% Structure: PlumeTrAP --> plume_parameters

function [height,width,plots,velocity,acceleration,tables] = ...
  plume_parameters(scale_fr,procframes,name,outFolder_orig,imageList_orig,...
  outFolder_proc,imageList_proc,outFolder_parameters,imgplume_height,pixel)

%% Calculation of plume parameters
% Define structures of output data
height.mean = zeros(length(imageList_proc),1); 
height.error = height.mean;

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

% Vent position
if isfield(pixel,'vent_pos_x') && isfield(pixel,'vent_pos_y')
else
    % Extimated vent position
    if procframes == 'y'
        figure(3)
    else
        figure(1)
    end
    imshow(imread(fullfile(outFolder_orig,...
        imageList_orig(length(imageList_orig)).name)));
    title('Extimated vent position')
    imgplume_last = logical(imread(fullfile(outFolder_proc,...
        imageList_proc(length(imageList_proc)).name))); % read last image as logical to get maximum height
    [row,~] = find(imgplume_last);
    pixel.vent_pos_y = max(row);
    pixel.vent_pos_x = round((find(imgplume_last(max(row),:),1,'last')+...
        find(imgplume_last(max(row),:),1))/2); % find vent pixel position
    images.roi.Point(gca,'Position',[pixel.vent_pos_x,pixel.vent_pos_y],...
        'Color','r','LineWidth',0.5);

    quest = 'Use extimated vent position?';
    opts.Interpreter = 'tex';
    opts.Default = 'Yes';
    VP = questdlg(quest,'Vent position','Yes','Pick vent position',opts);

    % Pick vent position
    if strcmp(VP,'Pick vent position') % pick vent position manually
        while 1
            if procframes == 'y'
                figure(3)
            else
                figure(1)
            end
            imshow(imread(imageList_orig(length(imageList_orig)).name))
            title('Pick vent position (use zoom in)')
            vent_pos = drawpoint('Color','r','LineWidth',0.5);
            pixel.vent_pos_x = round(vent_pos.Position(1));
            pixel.vent_pos_y = round(vent_pos.Position(2));

            quest = 'Do you want to proceed with this vent position?';
            opts.Interpreter = 'tex';
            opts.Default = 'Yes';
            pickVP = questdlg(quest,'Confirm vent position','Yes',...
                'Pick vent position',opts);

            if strcmp(pickVP,'Yes') % stops the while loop if the drawn ROI is good
                break
            end
        end
    end
end

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
    [velocity] = plumevelocity(j,time,height,velocity);
    
    % Accelerations of the plume head spreading in the atmosphere
    [acceleration] = plumeacceleration(j,time,velocity,acceleration);
    
    %% Progress and plots
    % Show progress of the analysis
    progress = j/length(imageList_proc);
    if j == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name',sprintf('Plume analysis'),...
            'Position',[325,140,270,50]);
    else % update the waitbar
        waitbar(progress,w,sprintf('Processing frame %d/%d',j,...
            length(imageList_proc)),'Name',sprintf('Plume analysis'),...
            'Position',[325,140,270,50]);
    end
    fprintf('Plume analysis %d/%d ...\n',j,length(imageList_proc))
    
    % Show plots
    if procframes == 'y'
        figure(3)
        fig = figure(3);
    else
        figure(1)
        fig = figure(1);
    end
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
    title('Plume velocity / acceleration vs t')
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
fprintf('End of %s.mp4 analysis\n',name)
end