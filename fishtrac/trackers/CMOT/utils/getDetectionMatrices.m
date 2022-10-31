function detMat = getDetectionMatrices(detections)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

F=length(detections);
Xd=zeros(F,0);
Yd=zeros(F,0);
Sd=zeros(F,0);

Xi=zeros(F,0);
Yi=zeros(F,0);
W=zeros(F,0);
H=zeros(F,0);
for t=1:length(detections);
    Dt=length(detections(t).xp);
    Xd(t,1:Dt)=detections(t).xp;
    Yd(t,1:Dt)=detections(t).yp;
    Sd(t,1:Dt)=detections(t).sc;
    
    Xi(t,1:Dt)=detections(t).xi;
    Yi(t,1:Dt)=detections(t).yi;
    W(t,1:Dt)=detections(t).wd;
    H(t,1:Dt)=detections(t).ht;
end

detMat.Xd=Xd;
detMat.Yd=Yd;
detMat.Sd=Sd;

detMat.Xi=Xi;detMat.Yi=Yi;detMat.W=W;detMat.H=H;