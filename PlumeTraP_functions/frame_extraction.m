%% frame_extraction - PlumeTraP
% Function to save a frame per second from a visible wavelenghts video
% Author: Riccardo Simionato. Date: February 2024
% Structure: PlumeTraP --> frame_extraction

function frame_extraction(vid,name,fr,scale_fr,n,outFolder_orig,ImageFormat)

fr_save = round(fr/scale_fr);
ext_list = ["*.png","*.jpg","*.jpeg","*.bmp","*.tif","*.tiff","*.gif"];
for el = 1:length(ext_list)
    delete(fullfile(outFolder_orig,ext_list(el)))
end

for f = 1:fr_save:n % saves a frame every fr_save frames
    frame = read(vid,f);
    num = (f-1)/fr_save; 
    numtot = fix((n-1)/fr_save+1); 
    progress = (num+1)/numtot;
    if num == 0 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Saving frame %d/%d',num,numtot),...
            'Name','Saving frames');
    else % update the waitbar
        waitbar(progress,w,sprintf('Saving frame %d/%d',num,numtot),...
            'Name','Saving frames');
    end
    seconds = num/scale_fr;
    decimal = num2str(seconds,'%.3f');
    decimal(1:length(decimal)-4) = [];
    num4name = sprintf('%04d%s',floor(seconds),decimal);
    imwrite(frame,fullfile(outFolder_orig,sprintf('%s-%s%s',name,...
        num4name,regexprep(ImageFormat,'[*]',''))));
end
fprintf('%s FRAMES SAVED\n',name)
close(w) % close the waitbar
beep % sound when finish

end