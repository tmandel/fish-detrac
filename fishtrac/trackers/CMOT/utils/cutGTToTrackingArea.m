function gtInfo=cutGTToTrackingArea(gtInfo)
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

global sceneInfo

Xgp=gtInfo.Xgp; Ygp=gtInfo.Ygp;
areaLimits=sceneInfo.trackingArea;

Xgp(Xgp<areaLimits(1))=0;Ygp(Ygp<areaLimits(3))=0;
Xgp(Xgp>areaLimits(2))=0;Ygp(Ygp>areaLimits(4))=0;
Ygp(Xgp==0)=0; Xgp(Ygp==0)=0;

allzeros=(Xgp == 0 | Ygp ==0);
gtInfo.X(allzeros)=0;gtInfo.Y(allzeros)=0;
gtInfo.W(allzeros)=0;gtInfo.H(allzeros)=0;
gtInfo.Xgp(allzeros)=0;gtInfo.Ygp(allzeros)=0;

% now clean up zero columns
gtInfo=cleanGT(gtInfo);

end