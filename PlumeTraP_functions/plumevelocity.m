%% plumevelocity - PlumeTraP
% Function to calculate the vertical rise velocity of a plume top
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> plume_parameters     --> plumevelocity
%            PlumeTraP --> plume_parameters_app --> plumevelocity
%            PlumeTraP --> manual_tracking      --> plumevelocity

function [velocity] = plumevelocity(j,time,pixel,height,velocity)

if j == 1
    velocity.inst(j) = 0; % Instantaneous velocity 
    velocity.inst_error(j) = 0;
    velocity.avg(j) = 0; % Time-averaged velocity
    velocity.avg_error(j) = 0;
else
    velocity.inst(j) = (height.mean(j)-height.mean(j-1))/(time(j)-time(j-1)); % Instantaneous velocity
    velocity.inst_error(j) = (((height.mean(j)+height.error(j)) - (height.mean(j-1)+height.error(j-1))) / (time(j)-time(j-1))) ...
        - (((height.mean(j)-height.error(j)) - (height.mean(j-1)-height.error(j-1))) / (time(j)-time(j-1))); % Half the uncertainty 
    velocity.avg(j) = height.mean(j)/time(j); % Time-averaged velocity
    velocity.avg_error(j) = (height.mean(j)+height.error(j))/time(j) ...
        - (height.mean(j)-height.error(j))/time(j); % Half the uncertainty
end

end