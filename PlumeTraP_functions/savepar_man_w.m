%% savepar_man_w - PlumeTraP
% Function to save the parameters obtained with manual tracking, with wind 
% correction
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> manual_tracking_w --> savepar_man_w

function [tables] = savepar_man_w(outFolder_parameters,name,time,height,...
    velocity,acceleration)

% Save parameters into a CSV file
w = waitbar(0,'Saving parameters into CSV file','Name','Saving file...');

tables.parameters = table(time,height.mean,height.error,...
    velocity.inst,velocity.inst_error,velocity.avg,velocity.avg_error,...
    acceleration.inst,acceleration.inst_error,acceleration.avg,...
    acceleration.avg_error);
tables.parameters.Properties.VariableNames = {'Time','Height','HeightError',...
    'VelocityInst','VelocityInstError','VelocityAvg',...
    'VelocityAvgError','AccelerationInst','AccelerationInstError',...
    'AccelerationAvg','AccelerationAvgError'};
writetable(tables.parameters,fullfile(outFolder_parameters,...
    sprintf('%s_parameters.csv',name)))
waitbar(0.33,w,'Saving parameters into CSV file','Name','Saving file...');

tables.wp_parameters = table(time,height.wp_mean,height.wp_error,...
    velocity.wp_inst,velocity.wp_inst_error,...
    velocity.wp_avg,velocity.wp_avg_error,acceleration.wp_inst,...
    acceleration.wp_inst_error,acceleration.wp_avg,acceleration.wp_avg_error);
tables.wp_parameters.Properties.VariableNames = {'Time','Height','HeightError',...
    'VelocityInst','VelocityInstError','VelocityAvg',...
    'VelocityAvgError','AccelerationInst','AccelerationInstError',...
    'AccelerationAvg','AccelerationAvgError'};
writetable(tables.wp_parameters,fullfile(outFolder_parameters,...
    sprintf('%s_wp_parameters.csv',name)))
waitbar(0.66,w,'Saving plot into PNG file','Name','Saving file...');

% Build and save the plot 
fig = figure(3);
fig.Units = 'normalized';
fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
subplot(2,1,1)
ip1 = plot(time,height.mean,'-','LineWidth',1);
ip1.Color = [0 0.4470 0.7410];
title(name,'image plane','Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
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
yyaxis right
wp3 = plot(time,velocity.wp_avg,'-','LineWidth',1);
wp3.Color = [0.6350 0.0780 0.1840];
wp4 = plot(time,acceleration.wp_avg,'-','LineWidth',1);
wp4.Color = [0.9290 0.6940 0.1250];
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
hold off
ax = gca;
ax.YAxis(2).Color = 'k';
legend({'Height','Velocity','Acceleration'},'Location','southeast',...
    'FontSize',8)
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.png',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.fig',name)))

waitbar(1,w,'Saving plot into PNG file','Name','Saving file...');
pause(1.0)
close(w)
end