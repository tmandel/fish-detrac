function stateInfo=postProcessState(stateInfo)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

global opt sceneInfo


if opt.track3d && opt.cutToTA
    stateInfo=cutStateToTrackingArea(stateInfo);
end

% if we tracked on image, Xi = X
if ~opt.track3d
    stateInfo.Xi=stateInfo.X; stateInfo.Yi=stateInfo.Y;
% otherwise project back
else
    stateInfo.Xgp=stateInfo.X; stateInfo.Ygp=stateInfo.Y;
    [stateInfo.Xi, stateInfo.Yi]=projectToImage(stateInfo.X,stateInfo.Y,sceneInfo);
end

%% get bounding boxes from corresponding detections
stateInfo=getBBoxesFromState(stateInfo);
% stateInfo=getBBoxesFromPrior(stateInfo);