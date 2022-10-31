function stateInfo = txt2stateInfo(resultSavePath, frameNums)

stateInfo.F = numel(frameNums);
stateInfo.frameNums = frameNums;

left = csvread([resultSavePath '_LX.txt']);
top = csvread([resultSavePath '_LY.txt']);
w = csvread([resultSavePath '_W.txt']);
h = csvread([resultSavePath '_H.txt']);
xc = left + w/2;
yc = top + h/2;

% foot position
stateInfo.X = xc;      
stateInfo.Xi = xc;
stateInfo.Y = yc+h/2;
stateInfo.Yi = yc+h/2;
stateInfo.H = h;
stateInfo.W = w;