function heightPrior=getHeightPrior(stateInfo)
% for 3d tracking we can compute
% an approximate average bounding box for each target
% which corresponds to a height of 1.70 m in the world
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.


global sceneInfo
camPar=sceneInfo.camPar;

% rx=camPar.mExt.mRx;ry=camPar.mExt.mRy;rz=camPar.mExt.mRz;
% tx=camPar.mExt.mTx;ty=camPar.mExt.mTy;tz=camPar.mExt.mTz;
% txi=camPar.mExt.mTxi;tyi=camPar.mExt.mTyi;tzi=camPar.mExt.mTzi;
% kappa=camPar.mInt.mKappa1; focal=camPar.mInt.mFocal;Sx=camPar.mInt.mSx;
% Dpx=camPar.mGeo.mDpx;Dpy=camPar.mGeo.mDpy;

% [mR mT]=getRotTrans(sceneInfo.camPar);

% feet
Z=0*ones(size(stateInfo.Xgp));
[Xi0 Yi0]=allWorldToImage_mex(stateInfo.Xgp,stateInfo.Ygp,Z, ...
    camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
    camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
    camPar.mR,camPar.mT);

% heads
Z=1700*ones(size(stateInfo.Xgp));
[XiH YiH]=allWorldToImage_mex(stateInfo.Xgp,stateInfo.Ygp,Z, ...
    camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
    camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
    camPar.mR,camPar.mT);

heightPrior=Yi0-YiH;

end