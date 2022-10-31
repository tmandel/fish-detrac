function gtInfo=cutGTToTrackingArea(gtInfo, sceneInfo)
% if we are tracking on ground plane
% remove all track segments outside tracking area


Xgp=gtInfo.Xgp; Ygp=gtInfo.Ygp;
areaLimits=sceneInfo.trackingArea;

Xgp(Xgp<areaLimits(1))=0;Ygp(Ygp<areaLimits(3))=0;
Xgp(Xgp>areaLimits(2))=0;Ygp(Ygp>areaLimits(4))=0;
Ygp(Xgp==0)=0; Xgp(Ygp==0)=0;

allzeros=(Xgp == 0 | Ygp ==0);
gtInfo.X(allzeros)=0;gtInfo.Y(allzeros)=0;
gtInfo.W(allzeros)=0;gtInfo.H(allzeros)=0;
gtInfo.Xgp(allzeros)=0;gtInfo.Ygp(allzeros)=0;

if isfield(gtInfo,'Xi')
    gtInfo.Xi(allzeros)=0;
    gtInfo.Yi(allzeros)=0;
end

% now clean up zero columns
gtInfo=cleanGT(gtInfo);

end