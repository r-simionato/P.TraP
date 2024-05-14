%% savepar_man - PlumeTraP
% Function to save the parameters obtained with manual tracking
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> manual_tracking --> savepar_man

function [tables] = savepar_man(outFolder_parameters,name,time,height,...
    velocity,acceleration,pixel)

tables.time = time;

% Save parameters into a CSV file
w = waitbar(0,'Saving parameters into CSV file','Name','Saving file...');

tables.parameters = table(time,pixel.h_row.',pixel.h_col.',height.mean,...
    height.error,velocity.inst,velocity.inst_error,velocity.avg,...
    velocity.avg_error,acceleration.inst,acceleration.inst_error,...
    acceleration.avg,acceleration.avg_error);
tables.parameters.Properties.VariableNames = {'Time','RowManTrack',...
    'ColManTrack','Height','HeightError','VelocityInst','VelocityInstError',...
    'VelocityAvg','VelocityAvgError','AccelerationInst',...
    'AccelerationInstError','AccelerationAvg','AccelerationAvgError'};    
writetable(tables.parameters,fullfile(outFolder_parameters,...
    sprintf('%s_parameters.csv',name)))
waitbar(0.5,w,'Saving plot into PNG file','Name','Saving file...');

% Build and save the plot
fig = figure(3);
fig.Units = 'normalized';
fig.Position = [0.05 0.1 0.9 0.8]; % maximize figure
title(name,'image plane','Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
[ph,~] = confplotrs(time,height.mean,height.error,height.error,"LineStyle","-","Color","#4363d8","LineWidth",1.5,"Marker","none");
hold off
hold on
yyaxis right
[pv,~] = confplotrs(time,velocity.avg,velocity.avg_error,velocity.avg_error,"LineStyle","-","Color","#800000","LineWidth",1.5,"Marker","none");
hold off
hold on
[pa,~] = confplotrs(time,acceleration.avg,acceleration.avg_error,acceleration.avg_error,"LineStyle","-","Color","#f58231","LineWidth",1.5,"Marker","none");
hold off
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
xlim([time(1) time(end)])
ax = gca;
ax.YAxis(2).Color = 'k';
legend([ph,pv,pa],{'Height','Velocity','Acceleration'},'Location','southeast',...
    'FontSize',10)
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.png',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.fig',name)))

waitbar(1,w,'Saving plot into PNG file','Name','Saving file...');
pause(1.0)
close(w)
end