function targetsExist=getTracksLifeSpans(X)
% create matrix with start and end points of tracks
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

N=size(X,2); targetsExist=zeros(N,2);
for i=1:N,
    targetsExist(i,1)=find(X(:,i),1,'first');          
    targetsExist(i,2)=find(X(:,i),1,'last');      
end

end