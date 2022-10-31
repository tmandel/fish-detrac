function targetsExist=getTracksLifeSpans(X)
% create Nx2 matrix with start and end points of tracks


N=size(X,2); targetsExist=zeros(N,2);
for i=1:N,
    targetsExist(i,1)=find(X(:,i),1,'first');          
    targetsExist(i,2)=find(X(:,i),1,'last');      
end

end