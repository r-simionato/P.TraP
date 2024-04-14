%% plumeacceleration_w - PlumeTraP
% Function to calculate the acceleration of a plume top with wind correction
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> plume_parameters_w --> plumeacceleration_w
%            PlumeTraP --> manual_tracking_w  --> plumeacceleration_w

function [acceleration] = plumeacceleration_w(j,time,velocity,acceleration)

% Calculation in the image plane (without wind correction)
if j == 1
  acceleration.inst(j) = 0; % Instantaneous acceleration
  acceleration.inst_error(j) = 0;
  acceleration.avg(j) = 0; % Time-averaged acceleration
  acceleration.avg_error(j) = 0;
else
  acceleration.inst(j) = (velocity.inst(j)-velocity.inst(j-1))/...
      (time(j)-time(j-1)); % Instantaneous acceleration
  acceleration.inst_error(j) = (velocity.inst_error(j)+...
      velocity.inst_error(j-1))*2; % Half the uncertainty 
  acceleration.avg(j) = velocity.avg(j)/time(j); % Time-averaged acceleration
  acceleration.avg_error(j) = velocity.avg_error(j)/time(j); % Half the uncertainty 
end

%% Calculation in the wind-corrected plane
%% CHANGE j WITH TIME(j)
if j == 1
    acceleration.wp_inst(j) = 0; 
    acceleration.wp_inst_error(j) = 0; % Instantaneous acceleration
    acceleration.wp_avg(j) = 0; 
    acceleration.wp_avg_error(j) = 0; % Time-averaged acceleration
else
    acceleration.wp_inst(j) = (velocity.wp_inst(j)-velocity.wp_inst(j-1))/...
        (time(j)-time(j-1)); % Instantaneous acceleration
    acceleration.wp_inst_error(j) = (velocity.wp_inst_error(j)-...
        velocity.wp_inst_error(j-1)); % Half the uncertainty
    acceleration.wp_avg(j) = velocity.wp_avg(j)/time(j); % Time-averaged acceleration
    acceleration.wp_avg_error(j) = velocity.wp_avg_error(j)/time(j); % Half the uncertainty
end
end