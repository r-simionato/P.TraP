%% plumevelocity_w - PlumeTraP
% Function to calculate the vertical rise velocity of a plume top with 
% wind correction
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> plume_parameters_w --> plumevelocity_w
%            PlumeTraP --> manual_tracking_w  --> plumevelocity_w

function [velocity] = plumevelocity_w(j,time,pixel,height,velocity)

% Calculation in the image plane (without wind correction)
if j == 1
    velocity.inst(j) = 0; % Instantaneous velocity 
    velocity.inst_error(j) = 0;
    velocity.avg(j) = 0; % Time-averaged velocity
    velocity.avg_error(j) = 0;
else
    velocity.inst(j) = (height.mean(j)-height.mean(j-1))/(time(j)-time(j-1)); % Instantaneous velocity
    velocity.inst_error(j) = (height.error(j)+height.error(j-1))*2; % Half the uncertainty 
    velocity.avg(j) = height.mean(j)/time(j); % Time-averaged velocity
    velocity.avg_error(j) = height.error_tot(j)-pixel.z_err(pixel.vent_pos_y); % Half the uncertainty
end

%% Calculation in the wind-corrected plane
%% CHANGE j WITH TIME(j)
if j == 1
    velocity.wp_inst(j) = 0; 
    velocity.wp_inst_error(j) = 0; % instantaneous velocity
    velocity.wp_avg(j) = 0; 
    velocity.wp_avg_error(j) = 0; % time-averaged velocity
else
    velocity.wp_inst(j) = (height.wp_mean(j)-height.wp_mean(j-1))/...
        (time(j)-time(j-1)); % instantaneous velocity
    velocity.wp_inst_error(j) = (height.wp_error_tot(j)- ...
        height.wp_error_tot(j-1));
    velocity.wp_avg(j) = height.wp_mean(j)/time(j); % time-averaged velocity
    velocity.wp_avg_error(j) = height.wp_error_tot(j)-...
        pixel.z_wp_err(pixel.vent_pos_y,pixel.vent_pos_x);
end
end