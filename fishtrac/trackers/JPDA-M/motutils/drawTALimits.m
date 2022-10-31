function drawTALimits(sceneInfo,t)
% draw a rectangle to visualize the
% limits of the tracking area
% 

c1=sceneInfo.trackingArea([1 3]);
c2=sceneInfo.trackingArea([2 3]);
c3=sceneInfo.trackingArea([2 4]);
c4=sceneInfo.trackingArea([1 4]);

if nargin==1
    camPar=sceneInfo.camPar;
else
    return;
end
[mR mT]=getRotTrans(camPar);

[slx sly]=worldToImage(c1(1),c1(2),0,mR,mT,camPar.mInt,camPar.mGeo);
x(1)=slx; y(1)=sly;

[slx sly]=worldToImage(c2(1),c2(2),0,mR,mT,camPar.mInt,camPar.mGeo);
x(2)=slx; y(2)=sly;

[slx sly]=worldToImage(c3(1),c3(2),0,mR,mT,camPar.mInt,camPar.mGeo);
x(3)=slx; y(3)=sly;

[slx sly]=worldToImage(c4(1),c4(2),0,mR,mT,camPar.mInt,camPar.mGeo);
x(4)=slx; y(4)=sly;

line([x x(1)],[y y(1)],'linewidth',2,'color','w','linestyle','--');

end