function [Xi Yi]=projectToImage(X,Y,sceneInfo)
% project all points from ground plane to image

Z=zeros(size(X));
camPar=sceneInfo.camPar;

if length(camPar)==1
    if camPar.ortho
        Xi=X./camPar.scale;
        Yi=(14000 - Y)./camPar.scale;
    else
    [mR mT]=getRotTrans(camPar);
    [Xi Yi]=allWorldToImage_mex(X,Y,Z, ...
        camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
        camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
        mR,mT);
    end
else
    F=size(X,1);
    Xi=zeros(size(X));Yi=zeros(size(X));
    for t=1:F
        camPar=sceneInfo.camPar(t);
        [mR mT]=getRotTrans(camPar);
        [Xi(t,:) Yi(t,:)]=allWorldToImage_mex(X(t,:),Y(t,:),Z(t,:), ...
            camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
            camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
            mR,mT);
    end
end

end