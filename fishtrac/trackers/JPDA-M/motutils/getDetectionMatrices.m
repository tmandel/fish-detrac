function detMat=getDetectionMatrices(detections)
% get X,Y matrices from struct


F=length(detections);
Xd=zeros(F,0);
Yd=zeros(F,0);
Sd=zeros(F,0);

Xi=zeros(F,0);
Yi=zeros(F,0);
W=zeros(F,0);
H=zeros(F,0);

direxist=isfield(detections(1),'dirx');
if direxist
    Dx=zeros(F,0);Dy=zeros(F,0);
    Dxi=zeros(F,0);Dyi=zeros(F,0);
end
for t=1:length(detections);
    Dt=length(detections(t).xp);
    Xd(t,1:Dt)=detections(t).xp;
    Yd(t,1:Dt)=detections(t).yp;
    Sd(t,1:Dt)=detections(t).sc;
    
    Xi(t,1:Dt)=detections(t).xi;
    Yi(t,1:Dt)=detections(t).yi;
    W(t,1:Dt)=detections(t).wd;
    H(t,1:Dt)=detections(t).ht;
    
    if direxist
        Dx(t,1:Dt)=detections(t).dirx;
        Dy(t,1:Dt)=detections(t).diry;

        Dxi(t,1:Dt)=detections(t).dirxi;
        Dyi(t,1:Dt)=detections(t).diryi;
        
    end
end

detMat.Xd=Xd;
detMat.Yd=Yd;
detMat.Sd=Sd;

detMat.Xi=Xi;detMat.Yi=Yi;detMat.W=W;detMat.H=H;
if direxist
    detMat.Dx=Dx;detMat.Dy=Dy;
    detMat.Dxi=Dxi;detMat.Dyi=Dyi;
end
