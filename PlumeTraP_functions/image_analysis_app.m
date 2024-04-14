%% image_analysis_app - PlumeTraP
% Function to apply image processing technique with input from GUI
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> app_FrameProcessing  --> image_analysis_app
%            PlumeTraP --> frame_processing_app --> image_analysis_app

function [img_start_bin,img_bin,img_backgr,img_rmout,img_plume_holes] = ...
    image_analysis_app(img,img_start,img_prec,i,mask,th_first,th_all,nousebkgr,...
    rgbuse_bkg,rgbuse_all)

[r,~,b] = imsplit(img_start); % split colour channels
if rgbuse_bkg == "br"
    img_start_subtract = b-r; % blue-red subtraction
elseif rgbuse_bkg == "b"
    img_start_subtract = b; % use only blue channel if blue and red channels are similar (e.g., cloudy sky)
end
if nousebkgr == 0
    img_start_bin = imfill(~imbinarize(img_start_subtract,th_first),'holes'); % binarize the image (Otsu if not specified) and keep only the bigger value 1 area
    img_start_bin = imkeepborder(img_start_bin,Borders=("bottom")); % keep only object touching the border (useful for topography)
    img_start_bin = imcomplement(img_start_bin); % reverse values for background subtraction
elseif nousebkgr == 1
    img_start_bin = ones(height(img_start),width(img_start)); % to not subtract the background
end

[r,~,b] = imsplit(img); % split colour channels
if rgbuse_all == "br"
    img_subtract = b-r; % blue-red subtraction
elseif rgbuse_all == "b"
    img_subtract = b; % use only blue channel if blue and red channels are similar (e.g., cloudy sky)
end
img_bin = imbinarize(img_subtract,th_all); % binarize the image (Otsu if not specified)
img_backgr = abs(img_bin-img_start_bin); % subtract the background (the first image)
if i>1 % read & process the previous frame to do a subtraction, then obtain a new subtracted image
    [r,~,b] = imsplit(img_prec); % split colour channels
    if rgbuse_all == "br"
        img_prec_subtract = b-r; % blue-red subtraction
    elseif rgbuse_all == "b"
        img_prec_subtract = b;
    end
    img_prec_bin = imbinarize(img_prec_subtract,th_all); % binarize the image (Otsu if not specified)
    img_prec_backgr = abs(img_bin-img_prec_bin); % subtract a previous frame
    img_backgr = img_backgr+img_prec_backgr; % combine the subtracted images
end
img_rmout = medfilt2(img_backgr,[3,3]); % remove outliers (set dimension)
img_rmout(~mask) = 0; % assign 0 value to all outside the mask
img_plume_bin = imbinarize(img_rmout); % need logical value
img_plume_area = bwareafilt(img_plume_bin,1); % keep only the bigger value 1 area
img_plume_holes = imfill(img_plume_area,'holes'); % fill the holes inside the plume

end