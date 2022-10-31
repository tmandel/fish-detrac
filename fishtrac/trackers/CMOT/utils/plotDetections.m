function plotDetections(plot3d, limits)
% plot detections as dots
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

global detections sceneInfo

hold on
% axis equal

dets=detections;
F=size(dets,2);
detcol=[.6 .6 .6];
maxFrames=200;
% plot3d=1;

% imshow(imread('/storage/databases/PETS2009/Crowd_PETS09/S3/Multiple_Flow/Time_12-43/View_001/frame_0026.jpg'));

if ~exist('plot3d','var'), plot3d=0; end

if plot3d
    for t=1:min(F,maxFrames)
%         t
%         t*ones(1,length(dets(t).xp))
%         pause
        plot3(dets(t).xp,dets(t).yp,t*ones(1,length(dets(t).xp)),'.','color',detcol);
        
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