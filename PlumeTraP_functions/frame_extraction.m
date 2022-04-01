%% frame_extraction - PlumeTraP
% Function to save a frame per second from a visible wavelenghts video
% Author: Riccardo Simionato. Date: March 2022
% Structure: PlumeTrAP --> frame_extraction

function frame_extraction(vid,name,fr,scale_fr,n,outFolder_orig,ImageFormat)

fr_save = round(fr/scale_fr);

for f = 1:fr_save:n %saves a frame every fr_save frames
    frame = read(vid,f);
    num = (f-1)/fr_save+1; 
    numtot = fix((n-1)/fr_save+1); 
    progress = num/numtot;
    if num == 1 % run a waitbar to show progress
        w = waitbar(progress,sprintf('Saving frame %d/%d',num,numtot),...
            'Name',sprintf('Saving %s.mp4 frames',name));
    else % update the waitbar
        waitbar(progress,w,sprintf('Saving frame %d/%d',num,numtot),...
            'Name',sprintf('Saving %s.mp4 frames',name));
    end
    fprintf('Saving frame %d/%d ...\n',num,numtot) % print in cmw too
    imwrite(frame,fullfile(outFolder_orig,sprintf('%s-%04d%s',name,...
        num,regexprep(ImageFormat,'[*]',''))));
end
fprintf('%s.mp4 FRAMES SAVED\n',name)
close(w) % close the waitbar
beep % sound when finish

end