function displayTrackingResult(sceneInfo, stateInfo)
% Display Tracking Result
%
% Take scene information sceneInfo and
% the tracking result from stateInfo
% 
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

% [~, ~, ~, ~, X Y]=getStateInfo(stateInfo);
W=stateInfo.W;
H=stateInfo.H;
Xi=stateInfo.Xi;
Yi=stateInfo.Yi;

options.defaultColor=[.1 .2 .9];
options.grey=.7*ones(1,3);
options.framePause=0.001; % pause between frames

options.traceLength=20; % overlay track from past n frames
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

% save?
% options.outFolder='tmp';

reopenFig('Tracking Results')
displayBBoxes(sceneInfo,stateInfo.frameNums,Xi,Yi,W,H,options)


end