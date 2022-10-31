function [detections nDets]=cutDetections(detections,nDets,sceneInfo, opt) 
% remove all detections that are
% outside the tracking area
% 

if opt.track3d && opt.cutToTA
    F=length(detections);
    Field = fieldnames(detections);
    nDets=0;
    for t=1:F
        tokeep=find(detections(t).xw>=sceneInfo.trackingArea(1) & ...
                    detections(t).xw<=sceneInfo.trackingArea(2) & ...
                    detections(t).yw>=sceneInfo.trackingArea(3) & ...
                    detections(t).yw<=sceneInfo.trackingArea(4));
                
                nDets=nDets+length(tokeep);

        for iField = 1:length(Field)
            fcontent=detections(t).(char(Field(iField)));
            fcontent=fcontent(tokeep);
            detections(t).(char(Field(iField)))=fcontent;
        end
    end
end

end % function
