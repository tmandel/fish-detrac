function gtInfo=cleanGT(gtInfo)
% remove zeros columns
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.


nzc=~~sum(gtInfo.X);

gtInfo.X=gtInfo.X(:,nzc);
gtInfo.Y=gtInfo.Y(:,nzc);
gtInfo.W=gtInfo.W(:,nzc);
gtInfo.H=gtInfo.H(:,nzc);

% nzc
% gtInfo.Xgp'
if isfield(gtInfo,'Xgp')
    gtInfo.Xgp=gtInfo.Xgp(:,nzc);
    gtInfo.Ygp=gtInfo.Ygp(:,nzc); 
end

% gtInfo.Xgp'
% also split fragmented trajectories
[F, N]=size(gtInfo.X);
for i=1:N
    frags=~~gtInfo.X(:,i);
    starts=find(frags(1:end-1)==frags(2:end)-1)+1;
    ends=find(frags(1:end-1)==frags(2:end)+1);
    if frags(1), starts=[1; starts]; end
    if frags(end), ends=[ends; numel(frags)]; end
    for s=2:numel(starts)
        gtInfo.X(starts(s):ends(s),end+1)=gtInfo.X(starts(s):ends(s),i);gtInfo.X(starts(s):ends(s),i)=0;
        gtInfo.Y(starts(s):ends(s),end+1)=gtInfo.Y(starts(s):ends(s),i);gtInfo.Y(starts(s):ends(s),i)=0;
        gtInfo.W(starts(s):ends(s),end+1)=gtInfo.W(starts(s):ends(s),i);gtInfo.W(starts(s):ends(s),i)=0;
        gtInfo.H(starts(s):ends(s),end+1)=gtInfo.H(starts(s):ends(s),i);gtInfo.H(starts(s):ends(s),i)=0;
        if isfield(gtInfo,'Xgp')
%             gtInfo.Xgp'
            gtInfo.Xgp(starts(s):ends(s),end+1)=gtInfo.Xgp(starts(s):ends(s),i);
%             gtInfo.Xgp'
            gtInfo.Xgp(starts(s):ends(s),i)=0;
%             gtInfo.Xgp'
            gtInfo.Ygp(starts(s):ends(s),end+1)=gtInfo.Ygp(starts(s):ends(s),i);gtInfo.Ygp(starts(s):ends(s),i)=0;
        end
    end
end