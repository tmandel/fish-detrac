function gtInfo=cropFramesFromGT(sceneInfo,gtInfo,frames,opt)
% remove unnecessary frkeep from GT
% 

global scenario;
if sceneInfo.gtAvailable
    
    
    frkeep=frames;
    if scenario>=195 && scenario<=199
        [a b frkeep]=intersect(frames,gtInfo.frameNums);
    end

    gtInfo.frameNums=gtInfo.frameNums(frkeep);
    gtInfo.X=gtInfo.X(frkeep,:);gtInfo.Y=gtInfo.Y(frkeep,:);
    gtInfo.W=gtInfo.W(frkeep,:);gtInfo.H=gtInfo.H(frkeep,:);
    if isfield(gtInfo,'Xgp')
        gtInfo.Xgp=gtInfo.Xgp(frkeep,:);gtInfo.Ygp=gtInfo.Ygp(frkeep,:);
    end
    gtInfo.Xi=gtInfo.Xi(frkeep,:);gtInfo.Yi=gtInfo.Yi(frkeep,:);
    gtInfo=cleanGT(gtInfo);
    
    if isfield(gtInfo,'dirxi')
        gtInfo.dirxi=gtInfo.dirxi(frkeep,:);gtInfo.diryi=gtInfo.diryi(frkeep,:);
    end
    if isfield(gtInfo,'dirxw')
        gtInfo.dirxw=gtInfo.dirxw(frkeep,:);gtInfo.diryw=gtInfo.diryw(frkeep,:);
    end
    if isfield(gtInfo,'dirx')
        gtInfo.dirx=gtInfo.dirx(frkeep,:);gtInfo.diry=gtInfo.diry(frkeep,:);
    end


end