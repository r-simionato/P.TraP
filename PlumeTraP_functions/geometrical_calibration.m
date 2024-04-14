%% geometric_calibration v1.0 - PlumeTraP
% Function to apply the geometric calibration
% Author: Riccardo Simionato. Date: October 2021
% Structure: PlumeTraP --> geometrical_calibration

function [pixel] = geometrical_calibration(imgplume_height,imgplume_width,...
    par,pixel)

%% Geometrical calibration
% Preallocate
pixel.z = zeros(imgplume_height,1);
pixel.z_err = pixel.z;
z_near = pixel.z;
z_err_near = pixel.z;
z_far = pixel.z;
z_err_far = pixel.z;
z_near_max = pixel.z;
z_near_min = pixel.z;
z_far_max = pixel.z;
z_far_min = pixel.z;
z_mean = pixel.z;
z_tot_err_near = pixel.z;
z_tot_err_far = pixel.z;
z_near_tot = pixel.z;
z_far_tot = pixel.z;

pixel.x = zeros(1,imgplume_width);
pixel.x_err = pixel.x;
x_near = pixel.x;
x_err_near = pixel.x;
x_far = pixel.x;
x_err_far = pixel.x;
x_near_max = pixel.x;
x_near_min = pixel.x;
x_far_max = pixel.x;
x_far_min = pixel.x;
x_mean = pixel.x;
x_tot_err_near = pixel.x;
x_tot_err_far = pixel.x;
x_near_tot = pixel.x;
x_far_tot = pixel.x;

% Vertical calibration
for j = imgplume_height:-1:1
    z_near_max(j) = par.min_dist*tand(par.phi-par.beta_v/2+...
        j*par.beta_v_pixel); % Maximum height of each pixel in the nearest possible image plane
    z_near_min(j) = par.min_dist*tand(par.phi-par.beta_v/2+...
        (j-1)*par.beta_v_pixel); % Minimum height of each pixel in the nearest possible image plane
    z_near(j) = (z_near_max(j)+z_near_min(j))/2; % Mean height of each pixel in the nearest possible image plane
    z_err_near(j) = (z_near_max(j)-z_near_min(j))/2; % Half the uncertainty related to the angle subtended by each pixel in the nearest possible image plane
    
    z_far_max(j) = par.max_dist*tand(par.phi-par.beta_v/2+...
        j*par.beta_v_pixel); % Maximum height of each pixel in the farthest possible image plane
    z_far_min(j) = par.max_dist*tand(par.phi-par.beta_v/2+...
        (j-1)*par.beta_v_pixel); % Minimum height of each pixel in the farthest possible image plane
    z_far(j) = (z_far_max(j)+z_far_min(j))/2; % Mean height of each pixel in the farthest possible image plane
    z_err_far(j) = (z_far_max(j)-z_far_min(j))/2; % Half the uncertainty related to the angle subtended by each pixel in the farthest possible image plane
    
    z_mean(j) = (z_near(j)+z_far(j))/2; % Mean of nearest and farthest height
    z_tot_err_near(j) = (z_far(j)-z_near(j))/2 +z_err_near(j); % Total error towards camera
    z_tot_err_far(j) = (z_far(j)-z_near(j))/2 +z_err_far(j); % Total error away from camera
    z_near_tot(j) = z_mean(j)-z_tot_err_near(j); % Lower possible height value
    z_far_tot(j) = z_mean(j)+z_tot_err_far(j); % Higher possible height value
    
    pixel.z(j) = (z_near_tot(j)+z_far_tot(j))/2; % Mean height
    pixel.z_err(j) = (z_far_tot(j)-z_near_tot(j))/2; % Half error of mean height
end

% Flip vectors
pixel.z = flip(pixel.z); 
pixel.z_err = flip(pixel.z_err); 

% Horizontal calibration
for i = imgplume_width:-1:1
    x_near_max(i) = par.min_dist*tand(par.beta_h/2)-par.min_dist*...
        (tand(par.beta_h/2-i*par.beta_h_pixel)); % Maximum width of each pixel in the nearest possible image plane
    x_near_min(i) = par.min_dist*tand(par.beta_h/2)-par.min_dist*...
        (tand(par.beta_h/2-(i-1)*par.beta_h_pixel)); % Minimum width of each pixel in the nearest possible image plane
    x_near(i) = (x_near_max(i)+x_near_min(i))/2; % Mean width of each pixel in the nearest possible image plane
    x_err_near(i) = par.min_dist/2*(tand(i*par.beta_h_pixel-par.beta_h/2)-...
        tand((i-1)*par.beta_h_pixel-par.beta_h/2)); % Half the uncertainty related to the angle subtended by each pixel in the nearest possible image plane
    
    x_far_max(i) = par.max_dist*tand(par.beta_h/2)-par.max_dist*...
        (tand(par.beta_h/2-i*par.beta_h_pixel)); % Maximum width of each pixel in the farthest possible image plane
    x_far_min(i) = par.max_dist*tand(par.beta_h/2)-par.max_dist*...
        (tand(par.beta_h/2-(i-1)*par.beta_h_pixel)); % Minimum width of each pixel in the farthest possible image plane
    x_far(i) = (x_far_max(i)+x_far_min(i))/2;% Mean width of each pixel in the farthest possible image plane
    x_err_far(i) = par.max_dist/2*(tand(i*par.beta_h_pixel-par.beta_h/2)-...
        tand((i-1)*par.beta_h_pixel-par.beta_h/2)); % Half the uncertainty related to the angle subtended by each pixel in the farthest possible image plane
    
    x_mean(i) = (x_near(i)+x_far(i))/2; % Mean of nearest and farthest width
    x_tot_err_near(i) = (x_far(i)-x_near(i))/2 +x_err_near(i); % Total error towards camera
    x_tot_err_far(i) = (x_far(i)-x_near(i))/2 +x_err_far(i); % Total error away from camera
    x_near_tot(i) = x_mean(i)-x_tot_err_near(i); % Lower possible width value
    x_far_tot(i) = x_mean(i)+x_tot_err_far(i); % Higher possible width value
    
    pixel.x(i) = (x_near_tot(i)+x_far_tot(i))/2; % Mean height
    pixel.x_err(i) = (x_far_tot(i)-x_near_tot(i))/2; % Half error of mean height
end
end