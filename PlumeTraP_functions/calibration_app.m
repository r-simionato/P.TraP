%% calibration_app - PlumeTraP
% Function to apply the geometric calbration and the wind correction with
% input from GUI
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> calibration_app

function [pixel,wdir] = calibration_app(gcal,wcor,procframes,...
    outFolder_proc,imageList_proc,outFolder_parameters,...
    imgplume_height,imgplume_width,par,geopot_nc,wind_nc,pixel,roiPos,name)

%% Geometrical calibration
if gcal == 'c' || gcal == 'i'
    [pixel] = geometrical_calibration(imgplume_height,imgplume_width,par,pixel);
end

%% Wind correction
if wcor == 1
    % Calculate wind from ERA5
    if isnan(par.wind_met)
        [par,windplot] = windERA5(outFolder_proc,imageList_proc,geopot_nc, ...
            wind_nc,roiPos,par,pixel);
        allplots = true;
    else
        % Wind direction specified in the input (par.wind_met)
        par.wind = mod(par.wind_met+180,360);
        allplots = false;
    end

    % Plots
    if procframes == true
        figure(3)
        fig = figure(3);
    else
        figure(1)
        fig = figure(1);
    end
    % Height vs wind direction
    if allplots == true
        subplot(1,2,1)
        plot(windplot.wind_met,windplot.h_vent,'b.','MarkerSize',10)
        hold on
        plot(par.wind_met, mean(windplot.h_vent),'r.','MarkerSize',10)
        hold off
        title('ERA5 wind direction')
        xlim([0 360])
        ylim([0 max(windplot.h_vent)+50])
        xlabel('Wind direction [°]')
        xticks([0 90, 180 270 360])
        grid('on')
        ylabel('Height [m above vent]')
        legend({'ERA5 wind direction values','Average wind direction'},'Location','southoutside',...
            'FontSize',6)
    end
    % Camera orientation & wind average direction
    if allplots == true
        axesHandle = subplot(1,2,2);
        pax = polaraxes('Units',axesHandle.Units,'Position',axesHandle.Position);
        delete(axesHandle);
    else
        pax = polaraxes;
    end
    hold on
    % Arrow parameters
    num_arrowlines = 100;
    pplot_l = 1; % arrow length in polar plot
    arrowhead_l = 1/20; % arrow head length relative arrow length in polar plot
    arrowhead_a = deg2rad(20); % angle of the arrow sides
    thetas = [atan((arrowhead_l.*tan(linspace(0,arrowhead_a,num_arrowlines/2)))./(pplot_l-arrowhead_l)),...
        -atan((arrowhead_l.*tan(linspace(0,arrowhead_a,num_arrowlines/2)))./(pplot_l-arrowhead_l))]; % arrow base coordinates
    % Arrow tip coordinates for omega
    ptheta.omega = repmat(deg2rad(par.omega),1,num_arrowlines);
    ptheta.omega_back = repmat(deg2rad(par.omega+180),1,num_arrowlines);
    prho.omega = repmat(pplot_l,1,num_arrowlines);
    p1 = polarplot(pax,[ptheta.omega(1) ptheta.omega(1)],[0 prho.omega(1)-0.9*arrowhead_l],'k','LineWidth',1.25);
    polarplot(pax,[ptheta.omega_back(1) ptheta.omega_back(1)],[0 1],'k','LineWidth',1.25)
    polarplot(pax,[ptheta.omega; ptheta.omega(1)+thetas],[prho.omega; (pplot_l-arrowhead_l)./cos(thetas)],'k')
    % Arrow tip coordinates for wind
    ptheta.wind = repmat(deg2rad(par.wind),1,num_arrowlines);
    ptheta.wind_back = repmat(deg2rad(par.wind+180),1,num_arrowlines);
    prho.wind = repmat(pplot_l,1,num_arrowlines);
    p2 = polarplot(pax,[ptheta.wind(1) ptheta.wind(1)],[0 prho.wind(1)-0.9*arrowhead_l],'r','LineWidth',1.25);
    polarplot(pax,[ptheta.wind_back(1) ptheta.wind_back(1)],[0 1],'r','LineWidth',1.25)
    polarplot(pax,[ptheta.wind; ptheta.wind(1)+thetas],[prho.wind; (pplot_l-arrowhead_l)./cos(thetas)],'r')
    % Arrow tip coordinates for strike
    ptheta.strike = repmat(deg2rad(par.omega+90),1,num_arrowlines);
    ptheta.strike_back = repmat(deg2rad(par.omega-90),1,num_arrowlines);
    p3 = polarplot(pax,[ptheta.strike(1) ptheta.strike(1)],[0 1],'--','Color',"#cccccc",'LineWidth',1.25);
    polarplot(pax,[ptheta.strike_back(1) ptheta.strike_back(1)],[0 1],'--','Color',"#cccccc",'LineWidth',1.25)
    hold off
    pax.ThetaDir = 'clockwise';
    pax.ThetaZeroLocation = 'top';
    pax.RGrid = 'off';
    pax.RTickLabel = [];
    par_omega_tick = par.omega;
    wind_dir_avg_tick = par.wind_met;
    for p = 0:4
        if par.omega == 90*p
            par_omega_tick = par.omega+0.001;
        end
        if par.wind == 90*p
            wind_dir_avg_tick = par.wind_met+0.001;
        end
    end
    pax.ThetaTick = sort([0 90 180 270 par_omega_tick wind_dir_avg_tick]);
    pax.ThetaTickLabel = [{sprintf('%.0fN',pax.ThetaTick(1))} {sprintf('%.0fN',pax.ThetaTick(2))} {sprintf('%.0fN',pax.ThetaTick(3))} {sprintf('%.0fN',pax.ThetaTick(4))} {sprintf('%.0fN',pax.ThetaTick(5))} {sprintf('%.0fN',pax.ThetaTick(6))}];
    title('Camera and wind direction')
    legend([p1 p2 p3],{'Camera orientation','Wind direction','Camera strike (image plane)'},'Location','southoutside','FontSize',6)

    saveas(fig,fullfile(outFolder_parameters,sprintf('%s_WindDirection.png',name)))

    % Apply correction for wind direction
    [pixel,wdir] = wind_correction(imgplume_height,imgplume_width,par,pixel);

elseif wcor == 0
    wdir = 'nowind';
end

end