function displayTrackingResult(sceneInfo, stateInfo, seqName)
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

W = stateInfo.W;
H = stateInfo.H;
Xi = stateInfo.Xi;
Yi = stateInfo.Yi;

reopenFig(['Tracking Results of Sequence ' seqName]);
displayBBoxes(sceneInfo, Xi, Yi, W, H);