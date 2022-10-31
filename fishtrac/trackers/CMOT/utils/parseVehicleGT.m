function gtInfo = parseVehicleGT(gtfile, frameNums)
% read ground truth bounding boxes
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

%% now parse
gt = load(gtfile);
for t = frameNums
    idx = find(gt(:,5) == t);
    for i = 1:numel(idx)
        h = gt(idx(i), 4) - gt(idx(i), 2) + 1;
        w = gt(idx(i), 3) - gt(idx(i), 1) + 1;
        xc = gt(idx(i), 1) + w/2;
        yc = gt(idx(i), 2) + h/2;
        id = gt(idx(i), 6);
        % foot position
        gtInfo.X(t,id)=xc;       gtInfo.Y(t,id)=yc+h/2;
        gtInfo.H(t,id)=h;        gtInfo.W(t,id)=w;
    end
end

gtInfo.frameNums = frameNums;
% remove zero columns
notEmpty = ~~sum(gtInfo.X);
gtInfo.X = gtInfo.X(:,notEmpty);
gtInfo.Y = gtInfo.Y(:,notEmpty);
gtInfo.W = gtInfo.W(:,notEmpty);
gtInfo.H = gtInfo.H(:,notEmpty);

end