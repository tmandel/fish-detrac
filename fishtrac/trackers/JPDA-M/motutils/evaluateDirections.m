function [allthetas gtOri]=evaluateDirections(detMatrices,gtInfo,eval3d)

assert(isfield(detMatrices,'Dx'),'detections must have orientations');

[F N]=size(gtInfo.X);
targetsExist=getTracksLifeSpans(gtInfo.X);
% gtOri.X=0;

X=gtInfo.Xgp;
Y=gtInfo.Ygp;
Xd=detMatrices.Xd;
Yd=detMatrices.Yd;
Dx=detMatrices.Dx;
Dy=detMatrices.Dy;

if ~eval3d
    X=gtInfo.Xi;
    Y=gtInfo.Yi;
    Xd=detMatrices.Xi;
    Yd=detMatrices.Yi;
    Dx=detMatrices.Dxi;
    Dy=detMatrices.Dyi;
end
% gtOri.X=zeros(size(X));
% gtOri.Y=zeros(size(X));



d1x=1; d1y=0;
d2x=-1; d2y=0;
allthetas=[];
for i=1:N
    tlength=diff(targetsExist(i,:))+1;       
    
    % Edyn is 0 for first and last frame
    for t=targetsExist(i,1)+1:targetsExist(i,2)-1
        % (a,b) = past frame position
        % (c,d) = current frame position
        % (e,f) = next frame position
        a=X(t-1,i);        b=Y(t-1,i);
        c=X(t,i);        d=Y(t,i);
        e=X(t+1,i);        f=Y(t+1,i);
        
        
        v1=([c; d] - [a; b]);
        v2=([e; f] - [c; d]);
        
        
        m1=sqrt(v1(1)^2 + v1(2)^2);
        m2=sqrt(v2(1)^2 + v2(2)^2);
        gtOri.X(t,i)=v2(1)/m2;
        gtOri.Y(t,i)=v2(2)/m2;
        
%         o1=v1./m1;   o2=v2./m2;
        ndet2=numel(find(detMatrices.Xd(t,:)));
        
        % only vertikal ones
        dets2=[Xd(t,1:ndet2);Yd(t,1:ndet2)];
        reppt=repmat([c;d],1,ndet2);        
        ddists2=sqrt(sum((dets2-reppt).^2));
        [mindist ddistsI]=min(ddists2);
%         mindist
%         ddists2
%         pause
%         ddists2=find(mindist<10000);
%         ddists2=ddists2(ddistsI);
            ddists2=ddistsI;
%         ddists2
        
%         f2acos=acos((v2(1)*d2x + v2(2)*d2y) / m2 );
%         v1'./m2
%         [d2x d2y]
%         rad2deg(f2acos)
%         pause
        
%         allthetas=[allthetas f2acos];

        for det2=ddists2
%             if abs(detMatrices.Dxi(t,det2))~=1
            d2x=Dx(t,det2);d2y=Dy(t,det2);d2=[d2x d2y];
            det2x=dets2(1,det2);det2y=dets2(2,det2);
            dist2=sqrt((c-det2x)^2 + (d-det2y)^2);
            
%             f2=1/(1+exp(-m2+so));
%             f2=f2*csig/(dist2^2+csig);
            f2acos=acos((v2(1)*d2x + v2(2)*d2y) / m2 );
            allthetas=[allthetas f2acos];
%             end

        end
%         allthetas
        
    end
end
        

end