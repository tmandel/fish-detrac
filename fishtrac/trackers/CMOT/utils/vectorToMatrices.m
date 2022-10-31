function [X Y]=vectorToMatrices(x,stateInfo)
% transforms the state vector X
% to matrix representation X and Y
% X and Y are FxN matrices
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

F=stateInfo.F; N=stateInfo.N;
% 
X=zeros(F,N);       % x-positions
Y=zeros(F,N);       % y-positions

% naive implementation
% targetsExist=stateInfo.targetsExist;
% 
% xind=1;
% for i=1:N
%     frames=targetsExist(i,1):targetsExist(i,2);
%     nFrames=numel(frames);
%     X(frames,i)=(x(xind:2:xind+2*nFrames-1));
%     
%     Y(frames,i)=(x(xind+1:2:xind+2*nFrames));
%     xind=xind+nFrames*2;
% end


% vectorized implementation
tiInd=find(stateInfo.tiToInd);
X(tiInd)=x(1:2:end);
Y(tiInd)=x(2:2:end);

end