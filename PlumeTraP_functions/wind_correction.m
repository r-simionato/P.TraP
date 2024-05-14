%% wind_correction - PlumeTraP
% Function to apply the wind correction
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> calibration --> wind_correction
%            PlumeTraP --> calibration_app --> wind_correction

function [pixel,wdir] = wind_correction(imgplume_height,imgplume_width,par,pixel)

% Get the angle between wind direction and image plane to perform wind calibration
if par.wind >= 180
    wind_prime = par.wind-180;
else
    wind_prime = par.wind;
end

if par.omega >= 0 && par.omega < 90
    delta = par.omega+90;
elseif par.omega >= 90 && par.omega < 270
    delta = par.omega-90;
elseif par.omega >= 270 && par.omega < 360
    delta = par.omega-270;
end

if abs(delta - wind_prime) < 90
    chi = abs(delta - wind_prime);
elseif abs(delta - wind_prime) > 90
    chi = 180-abs(delta - wind_prime);
elseif abs(delta - wind_prime) == 90 % in this case the wind calibration is not needed and calculation will be made on the image plane
    chi = 90;
end

if (par.wind - par.omega) > 0
    wind_sub_omega = par.wind - par.omega;
elseif (par.wind - par.omega) < 0
    wind_sub_omega = par.wind - par.omega + 360;
end

%
if isequal(round(chi),90)
    wdir = 'parallel'; % if wind direction is parallel to camera orientation
else
    wdir = num2str(chi);

    % Find x and y matrices
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
        x_ip_err(i) = abs(pixel.x_err(pixel.vent_pos_x)-pixel.x_err(i)); %m

        if (0 < wind_sub_omega) && (wind_sub_omega <= 90) || ...
                (180 < wind_sub_omega) && (wind_sub_omega < 270)

            x_shift(i) = x_ip(i)*sind(chi)/...
                (cosd(i*par.beta_h_pixel-par.beta_h/2+chi)); % Distance between pixel in the image plane and the same corrected
            x_shift_err(i) = x_ip_err(i)*sind(chi)/...
                (cosd(i*par.beta_h_pixel-par.beta_h/2+chi));

            if i <= pixel.vent_pos_x % Pixel to the left of the vent (values in m)
                pixel.x_wp_v(i) = x_ip(i) + x_shift(i)...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i) + x_shift_err(i)...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = -x_shift(i) *...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = -x_shift_err(i) *...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);

            elseif i > pixel.vent_pos_x % Pixel to the right of the vent (values in m)
                pixel.x_wp_v(i) = x_ip(i) - x_shift(i)...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i) - x_shift_err(i)...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = x_shift(i) *...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = x_shift_err(i) *...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
            end

        elseif (90 < wind_sub_omega) && (wind_sub_omega < 180) || ...
                (270 <= wind_sub_omega) && (wind_sub_omega < 360)

            x_shift(i) = x_ip(i)*...
                sind(chi)/(cosd(i*par.beta_h_pixel-par.beta_h/2-chi)); % Distance between pixel in the image plane and the same corrected
            x_shift_err(i) = x_ip_err(i)*...
                sind(chi)/(cosd(i*par.beta_h_pixel-par.beta_h/2-chi));

            if i <= pixel.vent_pos_x % Pixel to the left of the vent (values in m)
                pixel.x_wp_v(i) = x_ip(i) - x_shift(i) ...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i) - x_shift_err(i) ...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = x_shift(i) * ...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = x_shift_err(i) *...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);

            elseif i > pixel.vent_pos_x % Pixel to the right of the vent (values in m)
                pixel.x_wp_v(i) = x_ip(i) + x_shift(i) ...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);
                pixel.x_wp_v_err(i) = x_ip_err(i) + x_shift_err(i)...
                    * sind(par.beta_h/2-i*par.beta_h_pixel);

                pixel.y_wp(i) = -x_shift(i) *...
                    cosd(par.beta_h/2-i*par.beta_h_pixel);
                pixel.y_wp_err(i) = -x_shift_err(i) *...
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

    % Find z matrix
    pixel.z_wp = zeros(imgplume_height,imgplume_width);
    pixel.z_wp_err = pixel.z_wp;
    pixel.dist_vent = pixel.z_wp;
    pixel.dist_vent_err = pixel.z_wp;

    for j = imgplume_height:-1:1
        for i = imgplume_width:-1:1
            pixel.z_wp(j,i) = pixel.z(j) - pixel.y_wp(i)*...
                tand(par.phi-par.beta_v/2+j*par.beta_v_pixel); % Mean height corrected for wind
            pixel.z_wp_err(j,i) = pixel.z_err(j) - pixel.y_wp_err(i)*...
                tand(par.phi-par.beta_v/2+j*par.beta_v_pixel); % Error (pixel.z_wp +- pixel.z_wp_err)

            pixel.dist_vent(j,i) = sqrt(pixel.x_wp_v(i)^2 + ...
                pixel.y_wp(i)^2);
            pixel.dist_vent_err(j,i) = sqrt(pixel.x_wp_v_err(i)^2 + ...
                pixel.y_wp_err(i)^2);
        end
    end
end

end