function plotGT
% plot ground truth tracks
% 

global gtInfo opt

lw=3;
Xgt=gtInfo.Xi;Ygt=gtInfo.Yi;
if opt.track3d
    Xgt=gtInfo.Xgp;Ygt=gtInfo.Ygp;
end
[~, Ngt]=size(Xgt);
for id=1:Ngt
    exframes=find(Xgt(:,id));
    plot3(Xgt(exframes,id),Ygt(exframes,id),exframes,'--','color',[0.6 0.6 0.9],'linewidth',lw);
end

end