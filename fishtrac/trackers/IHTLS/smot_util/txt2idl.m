function idlDetections = txt2idl(detections, frameNums)

idlDetections = struct('rect',[],'xy',[]);
for i = frameNums
    idx = detections(:,1) == i;
    curDet = detections(idx, 3:7); 
    idlDetections(i).rect = curDet(:,1:4);
    idlDetections(i).xy = cat(2, (curDet(:,1)+curDet(:,3))/2, (curDet(:,2)+curDet(:,4))/2);
end