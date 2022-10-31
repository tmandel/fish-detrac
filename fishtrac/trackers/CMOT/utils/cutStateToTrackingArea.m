function stateInfo=cutStateToTrackingArea(stateInfo)
% if we are tracking on ground plane
% remove all track segments outside tracking area
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

global sceneInfo;

X=stateInfo.X; Y=stateInfo.Y;
areaLimits=sceneInfo.trackingArea;

X(X<areaLimits(1))=0;Y(Y<areaLimits(3))=0;
X(X>areaLimits(2))=0;Y(Y>areaLimits(4))=0;
Y(X==0)=0; X(Y==0)=0;

% now clean up zero columns
[X Y stateInfo]=cleanState(X,Y,stateInfo);

stateInfo.X=X; stateInfo.Y=Y;


end