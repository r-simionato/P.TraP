%% windcorrection - PlumeTraP
% Function to apply the wind correction if using calibration files
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> windcorrection

function [pixel,wdir] = windcorrection(pixel,procframes,...
    outFolder_proc,imageList_proc,imageList_orig,outFolder_parameters,...
    imgplume_height,imgplume_width,par,geopot_nc,wind_nc)

if isnan(par.wind)
    time = ncread(geopot_nc,'time');
    long = ncread(geopot_nc,'longitude'); % Read the parameters in MatLab
    lat = ncread(geopot_nc,'latitude');
    geopot = ncread(geopot_nc,'z');
    t = datetime(1900,1,1,time,0,0); % Convert hours since 1900-01-01 00:00:00.0 into a dd-Mmm-yyyy hh:00:00 format
    [row_t] = find(t == par.UTCdaytime); % Select time in the 4D matrix
    [row_lat] = find(lat == par.vent_lat); % Select latitude in the 4D matrix
    [row_long] = find(long == par.vent_long); % Select longitude in the 4D matrix
    geopot_sealevel = geopot(row_long,row_lat,:,row_t);
    height_sealevel = reshape(geopot_sealevel/9.80665,...
        [length(geopot_sealevel),1]);

    u_comp = ncread(wind_nc,'u');
    v_comp = ncread(wind_nc,'v'); % Read the parameters in MatLab
    u_comp = u_comp(row_long,row_lat,:,row_t);
    v_comp = v_comp(row_long,row_lat,:,row_t); % m/s

    wind_dir = zeros(length(height_sealevel),1);
    N_comp = wind_dir;
    E_comp = wind_dir;
    for d = 1:length(height_sealevel) % Calculate the wind direction basing on the northward and eastward velocity components
        if u_comp(d) >= 0
            wind_dir(d) = 90-atand(v_comp(d)/u_comp(d));
        elseif u_comp(d) < 0
            wind_dir(d) = 270-atand(v_comp(d)/u_comp(d));
        end
        N_comp(d) = v_comp(d);
        E_comp(d) = u_comp(d);
    end

    height_ventlevel = height_sealevel-par.vent_h; % Subtract the vent height to the wind heights matrix
    height_ventlevel = height_ventlevel(height_ventlevel >= 0); % Delete height values lower than zero
    for r_low = length(wind_dir):-1:length(height_ventlevel)+1 % Delete rows corresponding to negative height
        wind_dir(r_low,:) = [];
        N_comp(r_low,:) = [];
        E_comp(r_low,:) = []; 
    end
    imgplume_last = logical(imread(fullfile(outFolder_proc,...
        imageList_proc(length(imageList_proc)).name))); % read last image as logical to get maximum height
    [row,~] = find(imgplume_last);
    height_max = pixel.z(min(row))-pixel.z(max(row)); % plume maximum height
    heightoutofrange = height_ventlevel(height_ventlevel >= height_max); % Create a matrix of height out of maximum plume height range
    for r_high = length(heightoutofrange)-1:-1:1 % Delete rows corresponding to heights out of range
        height_ventlevel(r_high,:) = [];
        wind_dir(r_high,:) = [];
        N_comp(r_high,:) = [];
        E_comp(r_high,:) = [];
    end

    % Get the average wind direction
    if isempty(wind_dir)
        height_ventlevel = height_ventlevel_lower;
        wind_dir_avg = wind_dir_lower;
    else
        N_comp_mean = mean(N_comp);
        E_comp_mean = mean(E_comp);
        if E_comp_mean >= 0  
            wind_dir_avg = 90-atand(N_comp_mean/E_comp_mean);
        elseif E_comp_mean < 0
            wind_dir_avg = 270-atand(N_comp_mean/E_comp_mean);
        end
    end
else
    wind_dir_avg = par.wind; % Wind direction from the text file
end

%%
% Plots
if procframes == 'y'
    figure(3)
    fig = figure(3);
else
    figure(1)
    fig = figure(1);
end
fig.Units = "normalized";
fig.Position = [0.35,0.1,0.4,0.8];

% Height vs wind direction
if isnan(par.wind)
    subplot(2,2,1)
    plot(wind_dir,height_ventlevel,'b.','MarkerSize',10)
    hold on
    wind_dir_avg_havg = mean(height_ventlevel);
    plot(wind_dir_avg,wind_dir_avg_havg,'r.','MarkerSize',10)
    text(wind_dir_avg,wind_dir_avg_havg+50,sprintf('%.1f',wind_dir_avg))
    hold off
    title('Height vs wind direction')
    xlabel('Wind direction [°]')
    ylabel('Height [m]')
    legend({'wind values','average wind direction'},'Location','best',...
        'FontSize',6)
end

% Camera orientation & wind average direction
if isnan(par.wind)
    axesHandle = subplot(2,2,2);
    pax = polaraxes('Units',axesHandle.Units,'Position',axesHandle.Position);
    delete(axesHandle);
else
    pax = polaraxes;
end
p1 = polarhistogram(pax,deg2rad(par.omega),360,'EdgeColor',"k",'FaceColor',"k",'FaceAlpha',1); 
hold on
p2 = polarhistogram(pax,deg2rad(wind_dir_avg),360,'EdgeColor',"r",'FaceColor',"r",'FaceAlpha',1);
p3 = polarhistogram(pax,deg2rad(par.omega+90),360,'EdgeColor',"#cccccc",'FaceColor',"#cccccc",'FaceAlpha',1);
polarhistogram(pax,deg2rad(par.omega-90),360,'EdgeColor',"#cccccc",'FaceColor',"#cccccc",'FaceAlpha',1);
hold off
pax.ThetaDir = 'clockwise'; 
pax.ThetaZeroLocation = 'top'; 
pax.RGrid = 'off'; 
pax.RTickLabel = [];
pax.ThetaTick = sort([0 90 180 270 par.omega round(wind_dir_avg)]);
pax.ThetaTickLabel = [{sprintf('%.0fN',pax.ThetaTick(1))} {sprintf('%.0fN',pax.ThetaTick(2))} {sprintf('%.0fN',pax.ThetaTick(3))} {sprintf('%.0fN',pax.ThetaTick(4))} {sprintf('%.0fN',pax.ThetaTick(5))} {sprintf('%.0fN',pax.ThetaTick(6))}];
title('Camera & wind direction')
legend([p1 p2 p3],{'Camera direction','Wind direction','Camera strike (img plane)'},'Location','southoutside','FontSize',6)

% Extimated vent position
if isnan(par.wind)
    subplot(2,2,[3,4])
else
    subplot(2,2,2)
end
addpath(genpath(outFolder_parameters));
imshow(imread(fullfile(imageList_orig(length(imageList_orig)...
    ).folder,imageList_orig(length(imageList_orig)).name)))
title('Extimated vent position')
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
        if isnan(par.wind)
            subplot(2,2,[3,4])
        else
            subplot(2,2,2)
        end
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
% Save the plot
saveas(fig,fullfile(outFolder_parameters,'Wind&CameraOrientation.png'))

%%
% Get the angle between wind direction and image plane to perform wind calibration
if wind_dir_avg >= 180
    wind_dir_avg_cal = wind_dir_avg-180;
else
    wind_dir_avg_cal = wind_dir_avg;
end
if par.omega >= 0 && par.omega < 90
    delta = par.omega+90;
elseif par.omega >= 90 && par.omega < 270
    delta = par.omega-90;
elseif par.omega >= 270 && par.omega < 360
    delta = par.omega-270;
end
if abs(delta-wind_dir_avg_cal) < 90
    chi = abs(delta-wind_dir_avg_cal);
elseif abs(delta-wind_dir_avg_cal) > 90
    chi = 180-abs(delta-wind_dir_avg_cal);
elseif abs(delta-wind_dir_avg_cal) == 90 % in this case the wind calibration is not needed and calculation will be made on the image plane
    chi = 90;
end

% Apply correction for wind direction
if isequal(round(chi),90)
    wdir = 'parallel'; % if wind direction is parallel to camera orientation
else
    wdir = num2str(chi);

    pixel.x_wp = zeros(1,imgplume_width);
    pixel.x_wp_err = pixel.x_wp;
    pixel.x_wp_v = pixel.x_wp;
    pixel.x_wp_v_err = pixel.x_wp;
    x_ip = pixel.x_wp;
    x_ip_err = pixel.x_wp;
    x_shift = pixel.x_wp;
    x_shift_err = pixel.x_wp;
    pixel.y_wp = pixel.x_wp;
    pixel.y_wp_err = pixel.x_wp;

    for i = imgplume_width:-1:1
        x_ip(i) = abs(pixel.x(pixel.vent_pos_x)-pixel.x(i)); %m
%         x_ip_err(i) = pixel.x_err(pixel.vent_pos_x)+pixel.x_err(i); %m
x_ip_err(i) = abs(pixel.x_err(pixel.vent_pos_x)-pixel.x_err(i));

        if (par.omega<90 && ((wind_dir_avg >= par.omega && wind_dir_avg < ...
                par.omega+90) || (wind_dir_avg >= par.omega+180 && ...
                wind_dir_avg < par.omega+270))) ...
                || ...
                ((par.omega >= 90 && par.omega < 180) && ((wind_dir_avg >= ...
                par.omega && wind_dir_avg < par.omega+90) || (wind_dir_avg ...
                >= par.omega+180 || wind_dir_avg < par.omega-90))) ...
                || ...
                ((par.omega >= 180 && par.omega < 270) && ((wind_dir_avg >= ...
                par.omega && wind_dir_avg < par.omega+90) || (wind_dir_avg ...
                >= par.omega-180 && wind_dir_avg < par.omega-90))) ...
                || ...
                (par.omega >= 270 && ((wind_dir_avg >= par.omega || ...
                wind_dir_avg < par.omega-270) || (wind_dir_avg >= ...
                par.omega-180 && wind_dir_avg < par.omega-90)))

            x_shift(i) = x_ip(i)*sind(chi)/...
                (cosd(i*par.beta_h_pixel-par.beta_h/2+chi)); % Distance between pixel in the image plane and the same corrected
            x_shift_err(i) = x_ip_err(i)*sind(chi)/...
                (cosd(i*par.beta_h_pixel-par.beta_h/2+chi));

            if i <= pixel.vent_pos_x % Pixel to the left of the vent (values in m)
                pixel.x_wp_v(i) = x_ip(i)+...
                    x_shift(i)*sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i)+...
                    x_shift_err(i)*sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = -x_shift(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = -x_shift_err(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);

            elseif i > pixel.vent_pos_x % Pixel to the right of the vent (values in m)              
                pixel.x_wp_v(i) = x_ip(i)-...
                    x_shift(i)*sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i)-...
                    x_shift_err(i)*sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = x_shift(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = x_shift_err(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
            end

        elseif (par.omega<90 && ((wind_dir_avg >= par.omega+270 || ...
                wind_dir_avg < par.omega) || (wind_dir_avg >= par.omega+90 ...
                && wind_dir_avg < par.omega+180))) ...
                || ...
                ((par.omega >= 90 && par.omega < 180) && ((wind_dir_avg >= ...
                par.omega-90 && wind_dir_avg < par.omega) || (wind_dir_avg ...
                >= par.omega+90 && wind_dir_avg < par.omega+180))) ...
                || ...
                ((par.omega >= 180 && par.omega < 270) && ((wind_dir_avg >= ...
                par.omega-90 && wind_dir_avg < par.omega) || (wind_dir_avg ...
                >= par.omega+90 || wind_dir_avg < par.omega-180))) ...
                || ...
                (par.omega >= 270 && ((wind_dir_avg >= par.omega-90 && ...
                wind_dir_avg < par.omega) || (wind_dir_avg >= par.omega-270 ...
                && wind_dir_avg < par.omega-180)))

            x_shift(i) = x_ip(i)*...
                sind(chi)/(cosd(i*par.beta_h_pixel-par.beta_h/2-chi)); % Distance between pixel in the image plane and the same corrected
            x_shift_err(i) = x_ip_err(i)*...
                sind(chi)/(cosd(i*par.beta_h_pixel-par.beta_h/2-chi));

            if i <= pixel.vent_pos_x % Pixel to the left of the vent (values in m)                
                pixel.x_wp_v(i) = x_ip(i)-...
                    x_shift(i)*sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i)-...
                    x_shift_err(i)*sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = x_shift(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = x_shift_err(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);

            elseif i > pixel.vent_pos_x % Pixel to the right of the vent (values in m)
                pixel.x_wp_v(i) = x_ip(i)+...
                    x_shift(i)*sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i)+...
                    x_shift_err(i)*sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = -x_shift(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = -x_shift_err(i)*...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
            end
        end
    end

    % Adjust pixel.x_wp_v to get the distance from the leftmost pixel (not from the vent)
    for d = imgplume_width:-1:1
        if d <= pixel.vent_pos_x
            pixel.x_wp(d) = abs(pixel.x_wp_v(1)-pixel.x_wp_v(d));
            pixel.x_wp_err(d) = abs(pixel.x_wp_v_err(1)-pixel.x_wp_v_err(d));
        elseif d > pixel.vent_pos_x
            pixel.x_wp(d) = pixel.x_wp_v(1)+pixel.x_wp_v(d);
            pixel.x_wp_err(d) = pixel.x_wp_v_err(1)+pixel.x_wp_v_err(d);
        end
    end

    pixel.z_wp = zeros(imgplume_height,imgplume_width);
    pixel.z_wp_err = pixel.z_wp;

    for j = imgplume_height:-1:1
        for i = imgplume_width:-1:1
            if (par.omega < 90 && (wind_dir_avg < par.omega+90 || ...
                    wind_dir_avg > par.omega+270)) ...
                    || ...
                    (par.omega >= 270 && (wind_dir_avg > par.omega-90 || ...
                    wind_dir_avg < par.omega-270)) ...
                    || ...
                    ((par.omega >= 90 && par.omega < 270) && (wind_dir_avg ...
                    > par.omega-90 && wind_dir_avg < par.omega+90))

                pixel.z_wp(j,i) = pixel.z(j)+pixel.y_wp(i)*...
                    tand(par.phi-par.beta_v/2+j*par.beta_v_pixel); % Mean height corrected for wind
                pixel.z_wp_err(j,i) = pixel.z_err(j)+pixel.y_wp_err(i)*...
                    tand(par.phi-par.beta_v/2+j*par.beta_v_pixel); % Error (pixel.z_wp +- pixel.z_wp_err)

            else
                pixel.z_wp(j,i) = pixel.z(j)-pixel.y_wp(i)*...
                    tand(par.phi-par.beta_v/2+j*par.beta_v_pixel); % Mean height corrected for wind
                pixel.z_wp_err(j,i) = pixel.z_err(j)-pixel.y_wp_err(i)*...
                    tand(par.phi-par.beta_v/2+j*par.beta_v_pixel); % Error (pixel.z_wp +- pixel.z_wp_err)
            end
        end
    end
end

end