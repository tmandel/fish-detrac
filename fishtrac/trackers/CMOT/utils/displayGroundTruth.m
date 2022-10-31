function displayGroundTruth(sceneInfo, gtInfo)
% Display Ground Truth
%
% Take scene information sceneInfo and
% the ground truth from gtInfo
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

W=gtInfo.W;
H=gtInfo.H;


options.defaultColor=[.1 .2 .9];
options.grey=.7*ones(1,3);
options.framePause=0.01; % pause between frames

options.traceLength=20; % overlay data from past 10 frames
options.dotSize=20;
options.boxLineWidth=3;
options.traceWidth=2;

options.hideBG=0;

% what to display
options.displayDots=1;
options.displayBoxes=1;
options.displayID=0;
options.displayCropouts=0;
options.displayConnections=0;

X=gtInfo.X; Y=gtInfo.Y;

reopenFig('Ground Truth');
displayBBoxes(sceneInfo,gtInfo.frameNums,X,Y,W,H,options)

end