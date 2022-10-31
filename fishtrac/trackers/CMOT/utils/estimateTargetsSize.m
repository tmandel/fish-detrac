function htobj=estimateTargetsSize(sceneInfo)
% Take best n percent of detections
% and fit a 2d surface through their heights
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

npercent = 25; % best 25 %

% scenario=41;

% sceneInfo=getSceneInfo(scenario);
detections=parseDetections(sceneInfo);
allxi=[];allxi=[];allyi=[];allsc=[];allht=[];

F=length(detections);
for t=1:F
    allxi=[allxi detections(t).xi];
    allyi=[allyi detections(t).yi];
    allsc=[allsc detections(t).sc];
    allht=[allht detections(t).ht];
end
minheight=15;
%  goodones=find(allsc>0.75); % confident ones

[allsc goodones]=sort(allsc,'descend'); goodones=goodones(1:round(length(goodones)/(1/npercent*100))); 

allxi=allxi(goodones);allyi=allyi(goodones);allsc=allsc(goodones);allht=allht(goodones);
htobj=fit([allxi; allyi]',allht','poly21','Robust','on');

% %%
% clf
% 
% plot3(allxi,allyi,allht,'.'); box on
% xlim(sceneInfo.trackingArea(1:2));ylim(sceneInfo.trackingArea(3:4)); zlim([minheight sceneInfo.imgHeight]);
% set(gca,'Ydir','reverse');
% 
% hold on
% 
% %%
% 
% %%
% [xi yi]=meshgrid(1:50:sceneInfo.imgWidth, 1:50:sceneInfo.imgHeight);
% htsurface=feval(fitobj,xi(:),yi(:)); htsurface=reshape(htsurface,size(xi,1),size(xi,2));
% htsurface(htsurface<minheight)=minheight;
% htsurface(htsurface>sceneInfo.imgHeight)=sceneInfo.imgHeight;
% surf(xi,yi,htsurface)
% view(-78,34)