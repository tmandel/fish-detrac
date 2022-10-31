function [stateInfo, speed] = run_tracker(curSequence, baselinedetections)
%% tracker configuration
%% EB
sigma_l = curSequence.thre;
sigma_iou = 0.3;
sigma_p = 24;
sigma_len = 3;
skipframes = 0;
skip_factor = 3;

global options

pythonPath = [options.condaPath  '/fish_env/bin/python'];
%
%delete('results.mat')
%detects = (baselinedetections(:).');
%disp(curSequence);
delete('results.mat')
detects = (baselinedetections(:).');
save -6 detections.mat detects;

disp("running tracking alg");
numFrames = size(curSequence.frameNums,2);
ignore_regions = curSequence.ignoreRegion;
%disp(ignore_regions)
igrStr = "";
for i = 1:rows(ignore_regions)
  for j = 1:columns(ignore_regions)
    igrStr = [igrStr ',' num2str(ignore_regions(i,j))];
  end
end
if ~(strcmp(igrStr, ""))
 igrStr = substr(igrStr, 2);
end
%% running tracking algorithm
try
    time_start = tic;
	method = [pythonPath ' transCenter_wrapper.py detections.mat ' num2str(numFrames) ' ' num2str(curSequence.imgWidth) ' ' num2str(curSequence.imgHeight) ' ' curSequence.imgFolder ' ' igrStr]
	disp(method)
	system(method);
	stateInfo = [];
	stateInfo.Xi = dlmread('DAN_LX.txt');
	stateInfo.Yi = dlmread('DAN_LY.txt');
	stateInfo.W = dlmread('DAN_W.txt');
	stateInfo.H =  dlmread('DAN_H.txt');

	numRows = size(stateInfo.W,1);
	numCols = size(stateInfo.W,2);
	idealRows = size(curSequence.frameNums,2);
	numRows
	idealRows
	while (numRows < idealRows)
		stateInfo.Xi = [stateInfo.Xi; zeros(1, numCols)];
		stateInfo.Yi = [stateInfo.Yi; zeros(1, numCols)];
		stateInfo.H = [stateInfo.H; zeros(1, numCols)];
		stateInfo.W = [stateInfo.W; zeros(1, numCols)];
		numRows = size(stateInfo.W,1);
	end
    totalTime = toc(time_start);
    
    numRows = size(stateInfo.W,1);
	numCols = size(stateInfo.W,2);
    %numRows
    %numCols

	stateInfo.X = stateInfo.Xi;
	stateInfo.Y = stateInfo.Yi;
	stateInfo.frameNums = curSequence.frameNums;
    speed = numel(curSequence.frameNums)/totalTime; 
    %ret = py.iou_tracker.track_iou_matlab_wer(py.numpy.array(baselinedetections(:).'), sigma_l, sigma_iou, sigma_p, sigma_len, skipframes, skip_factor);
    
catch exception
    disp('error while calling the python tracking module: ')
    disp(' ')
    disp(exception)
	track_result = reshape(trackList.', 6, []).';
	%track_result

	%% convert and save the mot style track_result
	stateInfo = saveStateInfo(track_result, numel(curSequence.frameNums));
end

