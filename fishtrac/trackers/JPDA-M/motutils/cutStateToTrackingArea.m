function stateInfo=cutStateToTrackingArea(stateInfo,sceneInfo, opt)
% if we are tracking on ground plane
% remove all track segments outside tracking area


X=stateInfo.X; Y=stateInfo.Y;
areaLimits=sceneInfo.trackingArea;

X(X<areaLimits(1))=0;Y(Y<areaLimits(3))=0;
X(X>areaLimits(2))=0;Y(Y>areaLimits(4))=0;
Y(X==0)=0; X(Y==0)=0;

if isfield(stateInfo,'Xi')
    stateInfo.Xi(X==0)=0; stateInfo.Yi(Y==0)=0;
end
if isfield(stateInfo,'W')
    stateInfo.W(X==0)=0; stateInfo.H(Y==0)=0;
end

% now clean up zero columns
[X, Y, stateInfo]=cleanState(X,Y,stateInfo);

stateInfo.X=X; stateInfo.Y=Y;
if opt.track3d
    stateInfo.Xgp=X;stateInfo.Ygp=Y;
else
    stateInfo.Xi=X; stateInfo.Yi=Y;
end

end