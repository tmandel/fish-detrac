function detections = parseDetections(detSet, numFrames)

for i = numFrames
    idx = find(detSet(:,1) == i);
    left = detSet(idx,3);
    top = detSet(idx,4);
    right = detSet(idx,3) + detSet(idx,5) - 1;
    down = detSet(idx,4) + detSet(idx,6) - 1;
    
    detections(i).x = (left+right)/2;
    detections(i).y = (top+down)/2;
    detections(i).w = (right-left+1);
    detections(i).h = (down-top+1);
end    