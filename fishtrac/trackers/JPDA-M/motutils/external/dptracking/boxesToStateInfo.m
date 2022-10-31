function stateInfo=boxesToStateInfo(bboxes_tracked,sceneInfo)

global opt
stateInfo.frameNums=sceneInfo.frameNums;
stateInfo.F=length(stateInfo.frameNums);

% stateInfo.F
% length(bboxes_tracked)
assert(stateInfo.F==length(bboxes_tracked));

F=stateInfo.F;
Xi=zeros(F,0);
Yi=zeros(F,0);
W=zeros(F,0);
H=zeros(F,0);
for t=1:F
    if ~isempty(bboxes_tracked(t).bbox)
        ids=bboxes_tracked(t).bbox(:,5)';
        bx=bboxes_tracked(t).bbox(:,1)';
        by=bboxes_tracked(t).bbox(:,2)';
        wd=bboxes_tracked(t).bbox(:,3)'-bx;
        ht=bboxes_tracked(t).bbox(:,4)'-by;
        Xi(t,ids)=bx+wd/2;
        if opt.track3d
            Yi(t,ids)=by+ht/2;
        else
            Yi(t,ids)=by+ht;
        end
        W(t,ids)=wd;
        H(t,ids)=ht;
    end
    
end
stateInfo.X=Xi; stateInfo.Y=Yi;
stateInfo.Xi=Xi;stateInfo.Yi=Yi;stateInfo.W=W;stateInfo.H=H;
if opt.track3d
    [stateInfo.Xgp stateInfo.Ygp]=projectToGroundPlane(stateInfo.Xi, stateInfo.Yi, sceneInfo);
    stateInfo.X=stateInfo.Xgp;
    stateInfo.Y=stateInfo.Ygp;
end
[X Y stateInfo]=cleanState(stateInfo.X, stateInfo.Y,stateInfo);


end