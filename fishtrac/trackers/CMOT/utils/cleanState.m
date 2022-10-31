function [X Y stateInfo]=cleanState(X, Y,stateInfo)
% remove zero-columns from state
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

X=X(:,~~sum(X)); Y=Y(:,~~sum(Y));

% remove tracks shorter than minlife
minlife=3;
shorties=sum(~~X)<3;
X=X(:,~shorties); Y=Y(:,~shorties);
if isfield(stateInfo,'Xgp')
    stateInfo.Xgp=stateInfo.Xgp(:,~shorties);
    stateInfo.Ygp=stateInfo.Ygp(:,~shorties);
end

if isfield(stateInfo,'Xi')
    stateInfo.Xi=stateInfo.Xi(:,~shorties);
    stateInfo.Yi=stateInfo.Yi(:,~shorties);
end

stateInfo.X=X; stateInfo.Y=Y;
% also split fragmented trajectories
[F N]=size(X);
for i=1:N
    frags=~~stateInfo.X(:,i);
    starts=find(frags(1:end-1)==frags(2:end)-1)+1;
    ends=find(frags(1:end-1)==frags(2:end)+1);
    if frags(1), starts=[1; starts]; end
    if frags(end), ends=[ends; numel(frags)]; end
    for s=2:numel(starts)
        stateInfo.X(starts(s):ends(s),end+1)=stateInfo.X(starts(s):ends(s),i);stateInfo.X(starts(s):ends(s),i)=0;
        stateInfo.Y(starts(s):ends(s),end+1)=stateInfo.Y(starts(s):ends(s),i);stateInfo.Y(starts(s):ends(s),i)=0;
        if isfield(stateInfo,'Xi')
            stateInfo.Xi(starts(s):ends(s),end+1)=stateInfo.Xi(starts(s):ends(s),i);stateInfo.Xi(starts(s):ends(s),i)=0;
            stateInfo.Yi(starts(s):ends(s),end+1)=stateInfo.Yi(starts(s):ends(s),i);stateInfo.Yi(starts(s):ends(s),i)=0;
        end
        if isfield(stateInfo,'Xgp')
            stateInfo.Xgp(starts(s):ends(s),end+1)=stateInfo.Xgp(starts(s):ends(s),i);stateInfo.Xgp(starts(s):ends(s),i)=0;
            stateInfo.Ygp(starts(s):ends(s),end+1)=stateInfo.Ygp(starts(s):ends(s),i);stateInfo.Ygp(starts(s):ends(s),i)=0;
        end
    end
end

stateInfo.targetsExist=getTracksLifeSpans(X);
stateInfo.N=size(X,2);

stateInfo=matricesToVector(X,Y,stateInfo);

end