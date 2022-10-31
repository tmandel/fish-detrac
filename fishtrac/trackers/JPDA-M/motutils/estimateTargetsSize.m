function htobj=estimateTargetsSize(sceneInfo)
% Take best n percent of alldets
% and fit a 2d surface through their heights


npercent = 25; % best 25 %

% scenario=41;

% sceneInfo=getSceneInfo(scenario);
alldets=parseDetections(sceneInfo);

allxi=[];allxi=[];allyi=[];allsc=[];allht=[];

F=length(alldets);
for t=1:F
    allxi=[allxi alldets(t).xi];
    allyi=[allyi alldets(t).yi];
    allsc=[allsc alldets(t).sc];
    allht=[allht alldets(t).ht];
end
minheight=15;
%  goodones=find(allsc>0.75); % confident ones

[allsc goodones]=sort(allsc,'descend'); goodones=goodones(1:round(length(goodones)/(1/npercent*100))); 

allxi=allxi(goodones);allyi=allyi(goodones);allsc=allsc(goodones);allht=allht(goodones);
htobj=fit([allxi; allyi]',allht','poly11','Robust','on');

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