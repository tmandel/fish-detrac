function plotDetections(plot3d, limits)
% plot detections as dots

global detections sceneInfo

global gtInfo
% [gtInfo.F gtInfo.N]=size(gtInfo.X);
% gtInfo.targetsExist=getTracksLifeSpans(gtInfo.X);
% gtInfo=matricesToVector(gtInfo.Xgp,gtInfo.Ygp,gtInfo);

% [stateVec N F targetsExist stateInfo.X stateInfo.Y]=getStateInfo(gtInfo);
hold on
% axis equal

dets=detections;
F=size(dets,2);
detcol=[.6 .6 .6];
maxFrames=200;
% plot3d=1;

% imshow(imread('/storage/databases/PETS2009/Crowd_PETS09/S3/Multiple_Flow/Time_12-43/View_001/frame_0026.jpg'));

if ~exist('plot3d','var'), plot3d=0; end

dirlength=500;
if plot3d
    for t=1:min(F,maxFrames)
%         t
%         t*ones(1,length(dets(t).xp))
%         pause
        plot3(dets(t).xp,dets(t).yp,t*ones(1,length(dets(t).xp)),'.','color',detcol);
        
%         for d=1:length(dets(t).xp)
%             line([dets(t).xp(d) dets(t).xp(d)+dirlength*dets(t).dirx(d)], ...
%                 [dets(t).yp(d) dets(t).yp(d)+dirlength*dets(t).diry(d)], ...
%                 [t t]                );
%         end
%         
%         exgt=find(gtInfo.Xgp(t,:));
%         for gtid=exgt
%              plot3(gtInfo.Xgp(t,gtid),gtInfo.Ygp(t,gtid),t,'o','color','r');
%              dirx=[gtInfo.Xgp(t+1,gtid)-gtInfo.Xgp(t,gtid)];
%              diry=[gtInfo.Ygp(t+1,gtid)-gtInfo.Ygp(t,gtid)];
%              dirgt=[dirx; diry]; dirgt=dirgt./norm(dirgt);
%              
%             line([gtInfo.Xgp(t,gtid) gtInfo.Xgp(t,gtid)+dirlength*dirgt(1)], ...
%                 [gtInfo.Ygp(t,gtid) gtInfo.Ygp(t,gtid)+dirlength*dirgt(2)], ...
%                 [t t], 'color','r'                );             
%         end
%         pause
%         pause(.01)
    end
%     view(3)
%     zlim([0 min(F,maxFrames)]);
else
    for t=1:F
        plot(dets(t).xp,dets(t).yp,'.','color',detcol);
    end
    
end

if exist('limits','var')    
    if length(limits)==4 || length(limits)==6
        xlim(limits(1:2));
        ylim(limits(3:4));
%         if length(limits)==6
%             zlim(limits(5:6));
%         end
    else
        error('limits must be 4 or 6 long vector');
    end
else
    xlim(sceneInfo.trackingArea(1:2));
    ylim(sceneInfo.trackingArea(3:4));
end

pause(0.001);
end