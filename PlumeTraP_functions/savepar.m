%% savepar - PlumeTraP
% Function to save the obtained parameters
% Author: Riccardo Simionato. Date: March 2022
% Structure: PlumeTrAP --> plume_parameters --> savepar

function [tables] = savepar(outFolder_parameters,name,time,height,width,...
    velocity,acceleration,plots,procframes)

% Save parameters into a CSV file
w = waitbar(0,...
    sprintf('Saving %s.mp4 parameters into CSV file...',name),...
    'Name','Saving file...');
fprintf('SAVING %s.mp4 PARAMETERS INTO CSV FILE ...\n',name)

tables.parameters = table(time,height.mean,height.error,width.max,width.max_error,...
    velocity.inst,velocity.inst_error,velocity.avg,velocity.avg_error,...
    acceleration.inst,acceleration.inst_error,acceleration.avg,...
    acceleration.avg_error);
tables.parameters.Properties.VariableNames = {'Time','Height','HeightError','MaxWidth',...
    'MaxWidthError','VelocityInst','VelocityInstError','VelocityAvg',...
    'VelocityAvgError','AccelerationInst','AccelerationInstError',...
    'AccelerationAvg','AccelerationAvgError'};
writetable(tables.parameters,fullfile(outFolder_parameters,...
    sprintf('%s_parameters.csv',name)))
waitbar(0.3,w,...
    sprintf('Saving %s.mp4 parameters into CSV file...',name),...
    'Name','Saving file...');

Height = plots.height_tab; % needed to have the title in the table
Frame = width.rows;
tables.heightwidth = table(Height,Frame);
writetable(tables.heightwidth,fullfile(outFolder_parameters,...
    sprintf('%s_heightwidth.csv',name)))
waitbar(0.6,w,...
    sprintf('Saving %s.mp4 parameters into CSV file...',name),...
    'Name','Saving file...');
Height = plots.height_error_tab;
Frame = width.rows_error;
tables.heightwidth_err = table(Height,Frame);
writetable(tables.heightwidth_err,fullfile(outFolder_parameters,...
    sprintf('%s_heightwidth_err.csv',name)))
waitbar(0.9,w,...
    sprintf('Saving %s.mp4 parameters plot into PNG file...',name),...
    'Name','Saving file...');

% Build and save the plot
if procframes == 'y'
    figure(4)
    fig = figure(4);
else
    figure(2)
    fig = figure(2);
end
fig.Units = 'normalized';
fig.Position = [0 0 1 1]; % maximize figure
p1 = plot(time,height.mean,'-','LineWidth',1);
p1.Color = [0 0.4470 0.7410];
title(name)
xlabel('Time [s]')
ylabel('Length [m]')
hold on
p2 = plot(time,width.max,'-','LineWidth',1);
p2.Color = [0.4660 0.6740 0.1880];
yyaxis right
p3 = plot(time,velocity.avg,'-','LineWidth',1);
p3.Color = [0.6350 0.0780 0.1840];
p4 = plot(time,acceleration.avg,'-','LineWidth',1);
p4.Color = [0.9290 0.6940 0.1250];
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
hold off
ax = gca;
ax.YAxis(2).Color = 'k';
legend({'Height','Width','Velocity','Acceleration'},'Location','best',...
    'FontSize',8)
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.png',name)))

waitbar(1,w,...
    sprintf('Saving %s.mp4 parameters plot into PNG file...',name),...
    'Name','Saving file...');
pause(1.0)
close(w)
end