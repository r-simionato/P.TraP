%% plumeacceleration - PlumeTraP
% Function to calculate the acceleration of a plume top
% Author: Riccardo Simionato. Date: October 2023
% Structure: PlumeTraP --> plume_parameters     --> plumeacceleration
%            PlumeTraP --> plume_parameters_app --> plumeacceleration
%            PlumeTraP --> manual_tracking      --> plumeacceleration

function [acceleration] = plumeacceleration(j,time,velocity,acceleration)

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

end