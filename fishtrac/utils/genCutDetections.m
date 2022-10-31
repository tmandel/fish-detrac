function baselinedetections = genCutDetections(detections, idxDetections)

baselinedetections = detections(idxDetections,:);
frameNums = unique(baselinedetections(:,1));
for k = 1:length(frameNums)
    curLine = find(baselinedetections(:,1) == frameNums(k));  
    baselinedetections(curLine,2) = 1:numel(curLine);
end