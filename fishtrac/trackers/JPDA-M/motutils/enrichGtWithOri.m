%% enrich gt with Ori

[Fgt Ngt]=size(gtInfo.X);
targetsExist=getTracksLifeSpans(gtInfo.X);

X=gtInfo.Xgp;Y=gtInfo.Ygp;

% Xd=detMatrices.Xd;
% Yd=detMatrices.Yd;
% Dx=detMatrices.Dx;
% Dy=detMatrices.Dy;

for id=1:Ngt
    
    
    
    % all other frames
    for t=targetsExist(id,1):targetsExist(id,2)-1
        c=X(t,id);        d=Y(t,id);
        e=X(t+1,id);      f=Y(t+1,id);
        
        
        v2=([e; f] - [c; d]);
        
        
        m2=sqrt(v2(1)^2 + v2(2)^2);
        gtOri.Xgp(t,id)=v2(1)/m2;        gtOri.Ygp(t,id)=v2(2)/m2;
    end
    % last frame
    t=targetsExist(id,2);
    a=X(t-1,id);        b=Y(t-1,id);        c=X(t,id);        d=Y(t,id);
    v1=([c; d] - [a; b]);
    m1=sqrt(v1(1)^2 + v1(2)^2);
    gtOri.Xgp(t,id)=v1(1)/m1;
    gtOri.Ygp(t,id)=v1(2)/m1;


end


X=gtInfo.Xi;Y=gtInfo.Yi;

for id=1:Ngt
    
    
    
    % all other frames
    for t=targetsExist(id,1):targetsExist(id,2)-1
        c=X(t,id);        d=Y(t,id);
        e=X(t+1,id);      f=Y(t+1,id);
        
        
        v2=([e; f] - [c; d]);
        
        
        m2=sqrt(v2(1)^2 + v2(2)^2);
        gtOri.Xi(t,id)=v2(1)/m2;        gtOri.Yi(t,id)=v2(2)/m2;
    end
    % last frame
    t=targetsExist(id,2);
    a=X(t-1,id);        b=Y(t-1,id);        c=X(t,id);        d=Y(t,id);
    v1=([c; d] - [a; b]);
    m1=sqrt(v1(1)^2 + v1(2)^2);
    gtOri.Xi(t,id)=v1(1)/m1;
    gtOri.Yi(t,id)=v1(2)/m1;


end

gtInfo.dirxi=gtOri.Xi;gtInfo.diryi=gtOri.Yi;
gtInfo.dirxw=gtOri.Xgp;gtInfo.diryw=gtOri.Ygp;