function observation = parseDetection(detections, frameNums)

observation = cell(1, length(frameNums));
for i = frameNums
    idx = detections(:,1) == i;
    curDet = detections(idx, 3:6); 
    observation{i}.bbox = curDet;
end