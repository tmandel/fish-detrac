function printFinalEvaluation(trackingResultSavePath, gtInfo, frame_end)

% load stateInfo
left = load([trackingResultSavePath '_LX.txt']);
top = load([trackingResultSavePath '_LY.txt']);
right = load([trackingResultSavePath '_RX.txt']);
down = load([trackingResultSavePath '_RY.txt']);

stateInfo = [];
h = down - top;
w = right - left;
xc = left + w/2;
yc = top + h/2;
% foot position
stateInfo.X = xc;       
stateInfo.Y = yc+h/2;
stateInfo.H = h;
stateInfo.W = w;
stateInfo.F = frame_end;
stateInfo.frameNums = 1:frame_end;
stateInfo.Xgp = stateInfo.X;
stateInfo.Ygp = stateInfo.Y;
stateInfo.Xi = stateInfo.X;
stateInfo.Yi = stateInfo.Y;

% print result
printMessage(1,'\nEvaluation 2D:\n');
[metrics, metricsInfo]=CLEAR_MOT(gtInfo,stateInfo);
printMetrics(metrics,metricsInfo,1);   