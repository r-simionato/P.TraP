%% calibration - PlumeTraP
% Function to apply the geometric calbration and the wind correction
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> calibration

function [pixel,wdir] = calibration(gcal,wcor,procframes,...
    outFolder_proc,imageList_proc,imageList_orig,outFolder_parameters,...
    imgplume_height,imgplume_width,par,geopot_nc,wind_nc,pixel,name)

%% Geometrical calibration
if gcal == 'c'
    [pixel] = geometrical_calibration(imgplume_height,imgplume_width,par,pixel);
end

%% Wind correction
if wcor == 1
    % Plots
    if procframes == true
        figure(3)
        fig = figure(3);
    else
        figure(1)
        fig = figure(1);
    end
    fig.Units = "normalized";
    fig.Position = [0.35,0.1,0.4,0.8];

    % Extimated vent position
    subplot(2,2,[1,2])
    addpath(genpath(outFolder_parameters));
    imshow(imread(fullfile(imageList_orig(length(imageList_orig)...
        ).folder,imageList_orig(length(imageList_orig)).name)))
    title('Extimated vent position')
    pixel.vent_pos_y = max(row);
    imgplume_last = logical(imread(fullfile(outFolder_proc,...
        imageList_proc(length(imageList_proc)).name)));
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
            subplot(2,2,[1,2])
            imshow(imread(fullfile(imageList_orig(length(imageList_orig)...
                ).folder,imageList_orig(length(imageList_orig)).name)))
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

    % Calculate wind from ERA5
    if isnan(par.wind_met)
        roiPos = [1 1];
        [par,windplot] = windERA5(outFolder_proc,imageList_proc,geopot_nc, ...
            wind_nc,roiPos,par,pixel);

        allplots = true;
    else
        % Wind direction specified in the input (par.wind_met)
        par.wind = mod(par.wind_met+180,360);
        allplots = false;
    end

    % Plots
    % Height vs wind direction
    if allplots == true
        subplot(2,2,3)
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
        axesHandle = subplot(2,2,4);
        pax = polaraxes('Units',axesHandle.Units,'Position',axesHandle.Position);
        delete(axesHandle);
    else
        axesHandle = subplot(2,2,[3,4]);
        pax = polaraxes('Units',axesHandle.Units,'Position',axesHandle.Position);
        delete(axesHandle);
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

    % Save the plot
    saveas(fig,fullfile(outFolder_parameters,sprintf('%s_WindDirection.png',name)))

    % Apply correction for wind direction
    [pixel,wdir] = wind_correction(imgplume_height,imgplume_width,par,pixel);

elseif wcor == 0
    wdir = 'nowind';
end

end