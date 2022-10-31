function stateInfo=postProcessState(stateInfo)
% perform some necessary operation to finalize state

global opt sceneInfo


stInfo=stateInfo;
if opt.cutToTA
    stateInfo=cutStateToTrackingArea(stateInfo,sceneInfo, opt);
end

% quick hack
if ~size(stateInfo.X,2)
    stateInfo=stInfo;
end

% if we tracked on image, Xi = X
if ~opt.track3d
    stateInfo.Xi=stateInfo.X; stateInfo.Yi=stateInfo.Y;    
% otherwise project back
else
    if isfield(sceneInfo,'camPar')
        stateInfo.Xgp=stateInfo.X; stateInfo.Ygp=stateInfo.Y;
        [stateInfo.Xi, stateInfo.Yi]=projectToImage(stateInfo.X,stateInfo.Y,sceneInfo);
    else
        stateInfo.Xi=zeros(size(stateInfo.Xgp));
        stateInfo.Yi=zeros(size(stateInfo.Ygp));
    end
end

%% get bounding boxes from corresponding detections
stateInfo=getBBoxesFromState(stateInfo);
% YSHIFT
if ~opt.track3d && sceneInfo.yshift
    stateInfo.Yi=stateInfo.Yi+stateInfo.H/2;
end
% stateInfo=getBBoxesFromPrior(stateInfo);