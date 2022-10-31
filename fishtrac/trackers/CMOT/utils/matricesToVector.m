function stateInfo=matricesToVector(X,Y,stateInfo)
% takes the X,Y matrices and generates the state vector
% and a matrix containing x-indices to target/frame pairs
% e.g. ret(tiToInd(2,4)) = x-coordinate of target 4 at frame 2
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

F=stateInfo.F; N=stateInfo.N;

% naive implementation
% targetsExist=stateInfo.targetsExist;
% ret = zeros(1, sum(diff(targetsExist, 1, 2) + 1) * 2);
% tiToInd=zeros(F,N);
% xind=1;
% 
% for i=1:N
%     frames = targetsExist(i,1):targetsExist(i,2);
%     nFrames = numel(frames);
%     ret(xind : 2 : xind + 2 * nFrames - 2) = X(frames,i);
%     ret(xind + 1: 2 : xind + 2 * nFrames - 1) = Y(frames,i);
%     tiToInd(frames,i) = xind : 2 : xind + 2 * nFrames - 2;
%     xind = xind + nFrames * 2;
% end
% ret=ret';
 

% vectorized implementation
tiToInd=zeros(F,N);
extar=find(X);
nonzero=length(extar);
tiToInd(extar)=(1:nonzero)'*2-1;
ret=zeros(1,nonzero*2);
ret(1:2:end)=X(extar);ret(2:2:end)=Y(extar);

stateInfo.tiToInd=tiToInd;
stateInfo.stateVec=ret';