function [metrics2d, metrics3d, m2i, m3i, addInfo2d, addInfo3d]= ...
											getMetricsForEmptySolution()
% if we have a trivial solution, fill metrics appropriately

% zero metrics
zerosol=struct('frameNums',zeros(0,1),'X',[],'Y',[],'Xi',[],'Yi',[],'Xgp',[],'Ygp',[],'W',[],'H',[]);
[metrics2d m2i addInfo2d]= CLEAR_MOT(zerosol,zerosol);
[metrics3d m3i addInfo3d]= CLEAR_MOT(zerosol,zerosol);