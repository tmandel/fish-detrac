function detections = loadDetections(detFile)
%disp(detFile)
if(~exist(detFile, 'file'))
    error('no detection files');
else
    detections = load(detFile);      
end