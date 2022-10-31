function dets=detectionsToPirsiavash(detections)
ndets=length(detections);
dets=[];
dets.x=[detections.bx]';
dets.y=[detections.by]';
dets.w=[detections.wd]';
dets.h=[detections.ht]';
dets.r=[detections.sc]';
dets.fr=[];

for l=1:ndets
    dets.fr=[dets.fr;l*ones(length(detections(l).xp),1)];
end

end