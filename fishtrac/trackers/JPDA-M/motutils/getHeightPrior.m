function heightPrior=getHeightPrior(stateInfo)
% for 3d tracking we can compute
% an approximate average bounding box for each target
% which corresponds to a height of 1.70 m in the world
% 


global sceneInfo
camPar=sceneInfo.camPar;

% rx=camPar.mExt.mRx;ry=camPar.mExt.mRy;rz=camPar.mExt.mRz;
% tx=camPar.mExt.mTx;ty=camPar.mExt.mTy;tz=camPar.mExt.mTz;
% txi=camPar.mExt.mTxi;tyi=camPar.mExt.mTyi;tzi=camPar.mExt.mTzi;
% kappa=camPar.mInt.mKappa1; focal=camPar.mInt.mFocal;Sx=camPar.mInt.mSx;
% Dpx=camPar.mGeo.mDpx;Dpy=camPar.mGeo.mDpy;

% [mR mT]=getRotTrans(sceneInfo.camPar);

Z0=0*ones(size(stateInfo.Xgp));
% heads
ZH=1700*ones(size(stateInfo.Xgp));

if length(camPar)==1

    % feet

    [Xi0 Yi0]=allWorldToImage_mex(stateInfo.Xgp,stateInfo.Ygp,Z0, ...
        camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
        camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
        camPar.mR,camPar.mT);

    % heads
    [XiH YiH]=allWorldToImage_mex(stateInfo.Xgp,stateInfo.Ygp,ZH, ...
        camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
        camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
        camPar.mR,camPar.mT);

else
    F=size(stateInfo.Xgp,1);
    Xi0=zeros(size(stateInfo.Xgp));Yi0=zeros(size(stateInfo.Xgp));
    XiH=zeros(size(stateInfo.Xgp));YiH=zeros(size(stateInfo.Xgp));
    for t=1:F
    % feet
        camPar=sceneInfo.camPar(t);

        [Xi0(t,:) Yi0(t,:)]=allWorldToImage_mex(stateInfo.Xgp(t,:),stateInfo.Ygp(t,:),Z0(t,:), ...
            camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
            camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
            camPar.mR,camPar.mT);

        % heads
        [XiH(t,:) YiH(t,:)]=allWorldToImage_mex(stateInfo.Xgp(t,:),stateInfo.Ygp(t,:),ZH(t,:), ...
            camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
            camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
            camPar.mR,camPar.mT);
        
        
    end
end
heightPrior=Yi0-YiH;

end