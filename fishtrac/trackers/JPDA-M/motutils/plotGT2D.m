function plotGT2D(scen,from,to)
% plot ground truth tracks
% 


clf
hold on

% imgfile='/home/aanton/storage/databases/PETS2009/PETS-sunny-bg.png';
% img=imread(imgfile);

global gtInfo opt scenario
scenario=scen;
opt=getConOptions;
sceneInfo=getSceneInfo(scenario);
lw= 2;
ls='off';
x1=sceneInfo.trackingArea(1);
x2=sceneInfo.trackingArea(2);
y1=sceneInfo.trackingArea(3);
y2=sceneInfo.trackingArea(4);
xlim([sceneInfo.trackingArea(1:2)]);
ylim([sceneInfo.trackingArea(3:4)]);

% line([x1+10 x2-10 x2-10 x1+10 x1+10],[y1+10 y1+10 y2-10 y2-10 y1+10],'color','k');

% img=imresize(img,[y2-y1 x2-x1]);
% imagesc([x1 x2],[y1 y2],flipdim(img,1));
% set(gca,'YDir','reverse');
box on

Xgt=gtInfo.Xi;Ygt=gtInfo.Yi;
if opt.track3d
    Xgt=gtInfo.Xgp;Ygt=gtInfo.Ygp;
end
[~, Ngt]=size(Xgt);
for id=1:Ngt
    exframes=find(Xgt(:,id));
    exframes=intersect(exframes,from:to);
%     plot(Xgt(exframes,id),Ygt(exframes,id),'--','color',[0.6 0.6 0.9]);
    plot(Xgt(exframes,id),Ygt(exframes,id),'-','color',getColorFromID(id),'linewidth',lw,'linesmoothing',ls);
end
if ~opt.track3d
    set(gca,'YDir','reverse');
end
% set(gca,'FontSize',32);
% set(gca,'YDir','normal');
set(gca,'XTick',[]);set(gca,'YTick',[]);


% framestarts
% 20 - 1200
% 

end