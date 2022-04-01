%% image_analysis - PlumeTraP
% Function to apply image processing technique
% Author: Riccardo Simionato. Date: March 2022
% Structure: PlumeTrAP --> frame_processing --> image_analysis

function [img_start_bin,img_bin,img_backgr,img_rmout,img_plume_holes] = ...
    image_analysis(img,img_start,img_prec,i,mask,th_first,th_all,nb_size)

[r,~,b] = imsplit(img_start); % split colour channels
img_start_subtract = b-r; % blue-red subtraction
img_start_bin = imbinarize(img_start_subtract,th_first); % binarize the image (Otsu if not specified)

[r,~,b] = imsplit(img); % split colour channels
img_subtract = b-r; % blue-red subtraction
img_bin = imbinarize(img_subtract,th_all); % binarize the image (Otsu if not specified)
img_backgr = abs(img_bin-img_start_bin); % subtract the background (the first image)
if i>1 % read & process the previous frame to do a subtraction, then obtain a new subtracted image
    [r,~,b] = imsplit(img_prec); % split colour channels
    img_prec_subtract = b-r; % blue-red subtraction
    img_prec_bin = imbinarize(img_prec_subtract,th_all); % binarize the image (Otsu if not specified)
    img_prec_backgr = abs(img_bin-img_prec_bin); % subtract a previous frame
    img_backgr = img_backgr+img_prec_backgr; % combine the subtracted images
end
img_rmout = medfilt2(img_backgr,[nb_size,nb_size]); % remove outliers (set dimension)
img_rmout(~mask) = 0; % assign 0 value to all outside the mask
img_plume_bin = imbinarize(img_rmout); % need logical value
img_plume_area = bwareafilt(img_plume_bin,1); % keep only the bigger value 1 area
img_plume_holes = imfill(img_plume_area,'holes'); % fill the holes inside the plume

end