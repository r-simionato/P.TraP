%% savepar - PlumeTraP
% Function to save the obtained parameters
% Author: Riccardo Simionato. Date: October 2021
% Structure: PlumeTraP --> plume_parameters     --> savepar
%            PlumeTraP --> plume_parameters_app --> savepar

function [tables] = savepar(outFolder_parameters,name,time,height,width,...
    velocity,acceleration,plots,procframes)

% Save parameters into a CSV file
w = waitbar(0,'Saving parameters into CSV file','Name','Saving file...');

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
waitbar(0.3,w,'Saving parameters into CSV file','Name','Saving file...');

Height = plots.height_tab; % needed to have the title in the table
Frame = width.rows;
tables.heightwidth = table(Height,Frame);
writetable(tables.heightwidth,fullfile(outFolder_parameters,...
    sprintf('%s_heightwidth.csv',name)))
waitbar(0.6,w,'Saving parameters into CSV file','Name','Saving file...');
Height = plots.height_error_tab;
Frame = width.rows_error;
tables.heightwidth_err = table(Height,Frame);
writetable(tables.heightwidth_err,fullfile(outFolder_parameters,...
    sprintf('%s_heightwidth_err.csv',name)))
waitbar(0.9,w,'Saving plot into PNG file','Name','Saving file...');

% Build and save the plot
if procframes == true
    figure(4)
    fig = figure(4);
else
    figure(2)
    fig = figure(2);
end
fig.Units = 'normalized';
fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
p1 = plot(time,height.mean,'-','LineWidth',1);
p1.Color = [0 0.4470 0.7410];
title(name,'Interpreter','none')
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
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.fig',name)))

waitbar(1,w,'Saving plot into PNG file','Name','Saving file...');
pause(1.0)
close(w)
end