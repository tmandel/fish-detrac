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

pythonPath = [options.condaPath  '/DAN/bin/python'];
%
%delete('results.mat')
%detects = (baselinedetections(:).');
%disp(curSequence);
delete('results.mat')
detects = (baselinedetections(:).');
save -6 detections.mat detects;

disp("running tracking alg");
numFrames = size(curSequence.frameNums,2);
%% running tracking algorithm
try
	method = [pythonPath ' octave_wrapper.py detections.mat ' num2str(numFrames) ' ' num2str(curSequence.imgWidth) ' ' num2str(curSequence.imgHeight) ' ' curSequence.imgFolder];
	disp(method)
	system(method);
	load('results.mat')
    %ret = py.iou_tracker.track_iou_matlab_wrapper(py.numpy.array(baselinedetections(:).'), sigma_l, sigma_iou, sigma_p, sigma_len, skipframes, skip_factor);
    
catch exception
    disp('error while calling the python tracking module: ')
    disp(' ')
    disp(exception)
end
track_result = reshape(trackList.', 6, []).';
%track_result

%% convert and save the mot style track_result
stateInfo = saveStateInfo(track_result, numel(curSequence.frameNums));
