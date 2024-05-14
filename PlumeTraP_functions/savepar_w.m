%% savepar_w - PlumeTraP
% Function to save the obtained parameters with wind correction
% Author: Riccardo Simionato. Date: May 2024
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
title(name,'image plane','Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
[ph,~] = confplotrs(time,height.mean,height.error,height.error,"LineStyle","-","Color","#4363d8","LineWidth",1.5,"Marker","none");
hold off
hold on
[pw,~] = confplotrs(time,width.max,width.max_error,width.max_error,"LineStyle","-","Color","#b87bff","LineWidth",1.5,"Marker","none");
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
legend([ph,pw,pv,pa],{'Height','Width','Velocity','Acceleration'},'Location','southeast',...
    'FontSize',10)

subplot(2,1,2)
title(name,'wind-corrected plane','Interpreter','none')
xlabel('Time [s]')
ylabel('Length [m]')
hold on
[ph_wp,~] = confplotrs(time,height.wp_mean,height.wp_error,height.wp_error,"LineStyle","-","Color","#223ea4","LineWidth",1.5,"Marker","none");
hold off
hold on
[pw_wp,~] = confplotrs(time,width.max,width.max_error,width.max_error,"LineStyle","-","Color","#7b0aff","LineWidth",1.5,"Marker","none");
hold off
hold on
yyaxis right
[pv_wp,~] = confplotrs(time,velocity.wp_avg,velocity.wp_avg_error,velocity.wp_avg_error,"LineStyle","-","Color","#5a0000","LineWidth",1.5,"Marker","none");
hold off
hold on
[pa_wp,~] = confplotrs(time,acceleration.wp_avg,acceleration.wp_avg_error,acceleration.wp_avg_error,"LineStyle","-","Color","#c4570a","LineWidth",1.5,"Marker","none");
hold off
ylabel('Velocity [m/s] or Acceleration [m/s^2]')
xlim([time(1) time(end)])
ax = gca;
ax.YAxis(2).Color = 'k';
legend([ph_wp,pw_wp,pv_wp,pa_wp],{'Height','Width','Velocity','Acceleration'},'Location','southeast',...
    'FontSize',10)

saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.png',name)))
saveas(fig,fullfile(outFolder_parameters,sprintf('%s_Plot.fig',name)))

waitbar(1,w,'Saving plot into PNG file','Name','Saving file...');
pause(1.0)
close(w)
end