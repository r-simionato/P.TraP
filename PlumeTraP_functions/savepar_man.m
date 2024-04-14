%% savepar_man - PlumeTraP
% Function to save the parameters obtained with manual tracking
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> manual_tracking --> savepar_man

function [tables] = savepar_man(outFolder_parameters,name,time,height,...
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
waitbar(0.5,w,'Saving plot into PNG file','Name','Saving file...');

% Build and save the plot
fig = figure(3);
fig.Units = 'normalized';
fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
p1 = plot(time,height.mean,'-','LineWidth',1);
p1.Color = [0 0.4470 0.7410];
title(name,'Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
yyaxis right
p3 = plot(time,velocity.avg,'-','LineWidth',1);
p3.Color = [0.6350 0.0780 0.1840];
p4 = plot(time,acceleration.avg,'-','LineWidth',1);
p4.Color = [0.9290 0.6940 0.1250];
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
hold off
ax = gca;
ax.YAxis(2).Color = 'k';
legend({'Height','Velocity','Acceleration'},'Location','best',...
    'FontSize',8)
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.png',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.fig',name)))

waitbar(1,w,'Saving plot into PNG file','Name','Saving file...');
pause(1.0)
close(w)
end