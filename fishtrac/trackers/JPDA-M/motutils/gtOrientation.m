%% assign gt oreintation to detection

for t=1:length(detections)
    
    exgt=find(gtInfo.X(t,:));
    if isempty(exgt)
        detections(t).dirgtxi=ones(1,length(detections(t).xp));
        detections(t).dirgtyi=zeros(1,length(detections(t).xp));
        detections(t).dirgtxw=ones(1,length(detections(t).xp));
        detections(t).dirgtyw=zeros(1,length(detections(t).xp));
    else
        
        xd=detections(t).xi; yd=detections(t).yi;
        
        gtpos=[gtInfo.Xi(t,exgt);gtInfo.Yi(t,exgt)];
        ngtpos=size(gtpos,2);
        
        for iddet=1:length(xd)
            reppt=repmat([xd(iddet);yd(iddet)],1,ngtpos);
            ddists=sqrt(sum((gtpos-reppt).^2));
            
            %         pause
            [mindist ddistsI]=min(ddists);
            detections(t).dirgtxi(iddet)=gtInfo.dirxi(t,exgt(ddistsI));
            detections(t).dirgtyi(iddet)=gtInfo.diryi(t,exgt(ddistsI));     
%             [t iddet]
%             
%             mindist
%             ddists
%             ddistsI
%             gtInfo.dirxi(t,exgt(ddistsI))
%             pause
        end
        
        xd=detections(t).xw; yd=detections(t).yw;
        
        gtpos=[gtInfo.Xgp(t,exgt);gtInfo.Ygp(t,exgt)];
        ngtpos=size(gtpos,2);
        
        for iddet=1:length(xd)
            reppt=repmat([xd(iddet);yd(iddet)],1,ngtpos);
            ddists=sqrt(sum((gtpos-reppt).^2));
            
            %         pause
            [mindist ddistsI]=min(ddists);
            detections(t).dirgtxw(iddet)=gtInfo.dirxw(t,exgt(ddistsI));
            detections(t).dirgtyw(iddet)=gtInfo.diryw(t,exgt(ddistsI));           
        end        
        
        
        %         xw=detections(t).xw; yw=detections(t).yw;
        
    end
end

%%
for t=1:length(detections)
    detections(t).dirxi=detections(t).dirgtxi;
    detections(t).diryi=detections(t).dirgtyi;
    detections(t).dirxw=detections(t).dirgtxw;
    detections(t).diryw=detections(t).dirgtyw;
    detections(t).dirx=detections(t).dirgtxw;
    detections(t).diry=detections(t).dirgtyw;
end