%% savepar_w - PlumeTraP
% Function to save the obtained parameters with wind correction
% Author: Riccardo Simionato. Date: November 2021
% Structure: PlumeTraP --> plume_parameters_w --> savepar_w

function [tables] = savepar_w(outFolder_parameters,name,time,height,width,...
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
waitbar(0.11,w,'Saving parameters into CSV file','Name','Saving file...');

tables.wp_parameters = table(time,height.wp_mean,height.wp_error,width.wp_max,...
    width.wp_max_error,velocity.wp_inst,velocity.wp_inst_error,...
    velocity.wp_avg,velocity.wp_avg_error,acceleration.wp_inst,...
    acceleration.wp_inst_error,acceleration.wp_avg,acceleration.wp_avg_error);
tables.wp_parameters.Properties.VariableNames = {'Time','Height','HeightError','MaxWidth',...
    'MaxWidthError','VelocityInst','VelocityInstError','VelocityAvg',...
    'VelocityAvgError','AccelerationInst','AccelerationInstError',...
    'AccelerationAvg','AccelerationAvgError'};
writetable(tables.wp_parameters,fullfile(outFolder_parameters,...
    sprintf('%s_wp_parameters.csv',name)))
waitbar(0.22,w,'Saving parameters into CSV file','Name','Saving file...');

Height = plots.height_tab; % needed to have the title in the table
Frame = width.rows;
tables.heightwidth = table(Height,Frame);
writetable(tables.heightwidth,fullfile(outFolder_parameters,...
    sprintf('%s_heightwidth.csv',name)))
waitbar(0.33,w,'Saving parameters into CSV file','Name','Saving file...');
Height = plots.height_error_tab;
Frame = width.rows_error;
tables.heightwidth_err = table(Height,Frame);
writetable(tables.heightwidth_err,fullfile(outFolder_parameters,...
    sprintf('%s_heightwidth_err.csv',name)))
waitbar(0.44,w,'Saving plot into PNG file','Name','Saving file...');

tables.wp_rowsheight = table(plots.wp_height_tab);
writetable(tables.wp_rowsheight,fullfile(outFolder_parameters,...
    sprintf('%s_wp_rowsheight.csv',name)))
waitbar(0.55,w,'Saving plot into PNG file','Name','Saving file...');
tables.wp_rowswidth = table(width.wp_rows);
writetable(tables.wp_rowswidth,fullfile(outFolder_parameters,...
    sprintf('%s_wp_rowswidth.csv',name)))
waitbar(0.66,w,'Saving plot into PNG file','Name','Saving file...');
tables.wp_rowsheight_err = table(plots.wp_height_err_tab);
writetable(tables.wp_rowsheight_err,fullfile(outFolder_parameters,...
    sprintf('%s_wp_rowsheight_err.csv',name)))
waitbar(0.77,w,'Saving plot into PNG file','Name','Saving file...');
tables.wp_rowswidth_err = table(width.wp_rows_error);
writetable(tables.wp_rowswidth_err,fullfile(outFolder_parameters,...
    sprintf('%s_wp_rowswidth_err.csv',name)))
waitbar(0.88,w,'Saving plot into PNG file','Name','Saving file...');

% Build and save the plot 
if procframes == true
    figure(5)
    fig = figure(5);
else
    figure(3)
    fig = figure(3);
end
fig.Units = 'normalized';
fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
subplot(2,1,1)
ip1 = plot(time,height.mean,'-','LineWidth',1);
ip1.Color = [0 0.4470 0.7410];
title(name,'image plane','Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
ip2 = plot(time,width.max,'-','LineWidth',1);
ip2.Color = [0.4660 0.6740 0.1880];
yyaxis right
ip3 = plot(time,velocity.avg,'-','LineWidth',1);
ip3.Color = [0.6350 0.0780 0.1840];
ip4 = plot(time,acceleration.avg,'-','LineWidth',1);
ip4.Color = [0.9290 0.6940 0.1250];
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
hold off
ax = gca;
ax.YAxis(2).Color = 'k';
legend({'Height','Width','Velocity','Acceleration'},'Location','southeast',...
    'FontSize',8)
subplot(2,1,2)
wp1 = plot(time,height.wp_mean,'-','LineWidth',1);
wp1.Color = [0 0.4470 0.7410];
title(name,'wind-corrected plane','Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
wp2 = plot(time,width.wp_max,'-','LineWidth',1);
wp2.Color = [0.4660 0.6740 0.1880];
yyaxis right
wp3 = plot(time,velocity.wp_avg,'-','LineWidth',1);
wp3.Color = [0.6350 0.0780 0.1840];
wp4 = plot(time,acceleration.wp_avg,'-','LineWidth',1);
wp4.Color = [0.9290 0.6940 0.1250];
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
hold off
ax = gca;
ax.YAxis(2).Color = 'k';
legend({'Height','Width','Velocity','Acceleration'},'Location','southeast',...
    'FontSize',8)
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.png',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.fig',name)))

waitbar(1,w,'Saving plot into PNG file','Name','Saving file...');
pause(1.0)
close(w)
end