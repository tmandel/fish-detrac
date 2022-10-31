function [metrics2d, metrics3d]=evaluateCVML(resFile, gtFile, camFile)
% read a CVML file format for result and ground truth
% provide a camera calibration file and evaluate CLEAR MOT

sceneInfo.camPar=parseCameraParameters(camFile);

stateInfo=parseGT(resFile);
[stateInfo.Xgp, stateInfo.Ygp]=projectToGroundPlane(stateInfo.X, stateInfo.Y, sceneInfo);
stateInfo.Xi=stateInfo.X; stateInfo.Yi=stateInfo.Y;

gtInfo=parseGT(gtFile);
[gtInfo.Xgp, gtInfo.Ygp]=projectToGroundPlane(gtInfo.X, gtInfo.Y, sceneInfo);
gtInfo.Xi=gtInfo.X; gtInfo.Yi=gtInfo.Y;

%%
printMessage(1,'\nEvaluation 2D:\n');
[metrics2d, metricsInfo2d, addInfo2d]=CLEAR_MOT(gtInfo,stateInfo);
printMetrics(metrics2d,metricsInfo2d,1);

printMessage(1,'\nEvaluation 3D:\n');
evopt.eval3d=1;
[metrics3d, metricsInfo3d, addInfo3d]=CLEAR_MOT(gtInfo,stateInfo,evopt);
printMetrics(metrics3d,metricsInfo3d,1);
end