function stateInfo=removeOccluded(stateInfo)
% remove all boxes that are occluded >50%
%

assert(all(isfield(stateInfo,{'Xi','Yi','W','H'})), ...
    'stateInfo coordinates Xi,Yi,W,H needed for 2D evaluation');


Aw=stateInfo.W; Ah=stateInfo.H;
Ax=stateInfo.Xi-Aw/2; Ay=stateInfo.Yi-Ah;
Axr=Ax; Ayr=Ay; Awr=Aw; Ahr=Ah;

F=size(Ax,1);N=size(Ax,2);
toremove=zeros(size(Ax));
for t=1:F
    exobj=find(Aw(t,:));
    for id=exobj
        x1=Ax(t,id);y1=Ay(t,id);w1=Aw(t,id);h1=Ah(t,id);
        for id2=exobj
            if id~=id2
                x2=Ax(t,id2);y2=Ay(t,id2);w2=Aw(t,id2);h2=Ah(t,id2);
                
                if y1+h1>y2+h2
                    bisect=boxIntersect(x1,x1+w1,y1+h1,y1,x2,x2+w2,y2+h2,y2);
                    a2=w2*h2;
                    if bisect/a2 > .5
                        toremove(t,id2)=1;                    
                    end
%                     [t id id2]
%                     [bisect a2 bisect/a2]
%                     pause
                end
            end
        end
    end
end

toremove=find(toremove);
Axr(toremove)=0;
Ayr(toremove)=0;
Awr(toremove)=0;
Ahr(toremove)=0;
Ar=[Axr Ayr Awr Ahr];
stateInfo.Xi=Axr+Awr/2; stateInfo.Yi=Ayr+Ahr;
stateInfo.W=Awr; stateInfo.H=Ahr;
[stateInfo.Xi stateInfo.Yi stateInfo]=cleanState(stateInfo.Xi, stateInfo.Yi,stateInfo);

end

