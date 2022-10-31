function detections=setDetectionsIDs(detections,labeling)
% just for visualization

assert(length(labeling)==length([detections(:).xp]),...
        'length of labeling must equal length of detection');


F=length(detections);
laboffset=0;
for t=1:F
    for k=1:length(detections(t).xp)
        laboffset=laboffset+1;
        detections(t).id(k)=labeling(laboffset);
    end
end