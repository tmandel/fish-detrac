function detections = parseDetections(baselinedetections, frameNums)
% read detection file and create a struct array
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

global sequences

cnt = numel(frameNums);
detections(cnt).bx=[];
detections(cnt).by=[];
detections(cnt).xp=[];
detections(cnt).yp=[];
detections(cnt).ht=[];
detections(cnt).wd=[];
detections(cnt).sc=[];

detections(cnt).xi=[];
detections(cnt).yi=[];     
for t = frameNums
    cnt = t+1;
    idxObj = find(baselinedetections(:,1) == t);
    nObjects = numel(idxObj);
        bx =[];by=[];xp=[];yp=[];
        ht=[];wd=[];sc=[];
        xi=[];yi=[];           
    for j = 1:nObjects
        loc = baselinedetections(idxObj(j), 3:6);
        score = baselinedetections(idxObj(j), 7);
        left = loc(1);
        top = loc(2);
        width = loc(3);
        height = loc(4);
        xis = left + width/2;
        yis = top + height;
        bx = cat(2, bx, left);
        by=cat(2, by, top);
        xp=cat(2, xp, xis);
        yp=cat(2, xp, yis);
        ht=cat(2, ht, height);
        wd=cat(2, wd, width);
        sc=cat(2, sc, score);
        xi=cat(2, xi, xis);
        yi=cat(2, yi, yis);             
    end
    detections(cnt).bx=bx;
    detections(cnt).by=by;
    detections(cnt).xp=xp;
    detections(cnt).yp=yp;
    detections(cnt).ht=ht;
    detections(cnt).wd=wd;
    detections(cnt).sc=sc;

    detections(cnt).xi=xi;
    detections(cnt).yi=yi; 
end

%% set xp and yp accordingly
detections = setDetectionPositions(detections);
end

function detections = setDetectionPositions(detections)
    % set xp,yp to xi,yi if tracking is in image (2d)
    % set xp,yp to xw,yi if tracking is in world (3d)
    global options
    F = length(detections);
    if(options.track3d)
        assert(isfield(detections,'xw') && isfield(detections,'yw'), 'for 3D tracking detections must have fields ''xw'' and ''yw''');
        for t = 1:F
            detections(t).xp=detections(t).xw;
            detections(t).yp=detections(t).yw;        
        end
    else
        for t = 1:F
            detections(t).xp=detections(t).xi;
            detections(t).yp=detections(t).yi;
        end
    end
end