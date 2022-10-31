function evaluateDetections(detMatrices,gtInfo)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

global sceneInfo opt
if sceneInfo.gtAvailable
    detInfo=detMatrices; detInfo.frameNums=sceneInfo.frameNums;
    detInfo.X=detInfo.Xi; detInfo.Y=detInfo.Yi;
    [detInfo.F detInfo.N]=size(detInfo);

    if opt.track3d
        detInfo=cutStateToTrackingArea(detInfo);
%         gtInfo=cutGTToTrackingArea(gtInfo);
    end

    printMessage(1,'\nDetections Evaluation (2D):\n');
    [metrics metricsInfo]=CLEAR_MOT(gtInfo,detInfo,struct('eval3d',0));
    printMetrics(metrics,metricsInfo,1,[1 2 3 8 9]);
    printMessage(1,'\n');
end

end