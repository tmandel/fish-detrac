function saveResultsNoDetections(resultSavePath)

% save empty tracking results
dlmwrite([resultSavePath '_LX.txt'], []);
dlmwrite([resultSavePath '_LY.txt'], []);
dlmwrite([resultSavePath '_W.txt'], []);
dlmwrite([resultSavePath '_H.txt'], []);
dlmwrite([resultSavePath '_speed.txt'], []);       