function detections = dropDetections(detections, ignoreFile, imgHeight, imgWidth)

% drop detections in ignore region
ignoreRegion = load(ignoreFile);
if(~isempty(ignoreRegion))
    igrMap = zeros(imgHeight, imgWidth);
    numIgnore = size(ignoreRegion,1);
    for j = 1:numIgnore
        igrMap(ignoreRegion(j,2):min(imgHeight,ignoreRegion(j,2)+ignoreRegion(j,4)),ignoreRegion(j,1):min(imgWidth,ignoreRegion(j,1)+ignoreRegion(j,3))) = 1;
    end
    intIgrMap = createIntImg(double(igrMap));
    idxIgnoreLeft = [];
    for i = 1:size(detections, 1)
        curDet = max(1,round(detections(i,3:6)));
        x = max(1, min(imgWidth, curDet(1)));
        y = max(1, min(imgHeight, curDet(2)));
        w = curDet(3);
        h = curDet(4);
        tl = intIgrMap(y, x);
        tr = intIgrMap(y, min(imgWidth,x+w));
        bl = intIgrMap(max(1,min(imgHeight,y+h)), x);
        br = intIgrMap(max(1,min(imgHeight,y+h)), min(imgWidth,x+w));
        ignoreValue = tl + br - tr - bl; 
        if(ignoreValue/(h*w)<0.5)
            idxIgnoreLeft = cat(1, idxIgnoreLeft, i);
        end
    end
    detections = detections(idxIgnoreLeft, :);
end