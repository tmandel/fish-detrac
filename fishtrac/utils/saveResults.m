function saveResults(trackingResultSavePath, stateInfo, speed)

% save tracking results
dlmwrite([trackingResultSavePath '_LX.txt'], stateInfo.X-stateInfo.W/2);
dlmwrite([trackingResultSavePath '_LY.txt'], stateInfo.Y-stateInfo.H);
dlmwrite([trackingResultSavePath '_W.txt'], stateInfo.W);
dlmwrite([trackingResultSavePath '_H.txt'], stateInfo.H);
dlmwrite([trackingResultSavePath '_speed.txt'], speed);      