function stateInfo=mergeTracks(stateInfo, id1, id2)


interpmeth='spline';
interpmeth='linear';

exfr1=find(stateInfo.X(:,id1));
exfr2=find(stateInfo.X(:,id2));

newframes=[exfr1; exfr2];
% interpmeth='spline';
onecolX=[stateInfo.X(exfr1,id1);stateInfo.X(exfr2,id2)];
onecolY=[stateInfo.Y(exfr1,id1);stateInfo.Y(exfr2,id2)];
onecolW=[stateInfo.W(exfr1,id1);stateInfo.W(exfr2,id2)];
onecolH=[stateInfo.H(exfr1,id1);stateInfo.H(exfr2,id2)];

onecolX=interp1(newframes,onecolX,newframes(1):newframes(end),interpmeth);
onecolY=interp1(newframes,onecolY,newframes(1):newframes(end),interpmeth);
onecolW=interp1(newframes,onecolW,newframes(1):newframes(end),interpmeth);
onecolH=interp1(newframes,onecolH,newframes(1):newframes(end),interpmeth);

stateInfo.X(newframes(1):newframes(end),id1)=onecolX';
stateInfo.Y(newframes(1):newframes(end),id1)=onecolY';
stateInfo.W(newframes(1):newframes(end),id1)=onecolW';
stateInfo.H(newframes(1):newframes(end),id1)=onecolH';

N=size(stateInfo.X,2);
keepids=setdiff(1:N,id2);
stateInfo.X(:,id2)=0;stateInfo.Y(:,id2)=0;stateInfo.W(:,id2)=0;stateInfo.H(:,id2)=0;
% stateInfo.X=stateInfo.X(:,keepids);stateInfo.Y=stateInfo.Y(:,keepids);
% stateInfo.W=stateInfo.W(:,keepids);stateInfo.H=stateInfo.H(:,keepids);

if isfield(stateInfo,'Xi')
    onecolXi=[stateInfo.Xi(exfr1,id1);stateInfo.Xi(exfr2,id2)];
    onecolYi=[stateInfo.Yi(exfr1,id1);stateInfo.Yi(exfr2,id2)];
    onecolXi=interp1(newframes,onecolXi,newframes(1):newframes(end),interpmeth);
    onecolYi=interp1(newframes,onecolYi,newframes(1):newframes(end),interpmeth);
    stateInfo.Xi(newframes(1):newframes(end),id1)=onecolXi';
    stateInfo.Yi(newframes(1):newframes(end),id1)=onecolYi';
%     stateInfo.Xi(:,id2)=0;stateInfo.Yi(:,id2)=0;
%     stateInfo.Xi=stateInfo.Xi(:,keepids);stateInfo.Yi=stateInfo.Yi(:,keepids);
end
if isfield(stateInfo,'Xgp')
    onecolXgp=[stateInfo.Xgp(exfr1,id1);stateInfo.Xgp(exfr2,id2)];
    onecolYgp=[stateInfo.Ygp(exfr1,id1);stateInfo.Ygp(exfr2,id2)];
    onecolXgp=interp1(newframes,onecolXgp,newframes(1):newframes(end),interpmeth);
    onecolYgp=interp1(newframes,onecolYgp,newframes(1):newframes(end),interpmeth);
    stateInfo.Xgp(newframes(1):newframes(end),id1)=onecolXgp';
    stateInfo.Ygp(newframes(1):newframes(end),id1)=onecolYgp';
%     stateInfo.Xgp(:,id2)=0;stateInfo.Ygp(:,id2)=0;
%     stateInfo.Xgp=stateInfo.Xgp(:,keepids);stateInfo.Ygp=stateInfo.Ygp(:,keepids);
end

% [X Y stateInfo]=cleanState(X, Y,stateInfo);


end