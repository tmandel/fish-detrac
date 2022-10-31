function [stateInfo, speed] = run_tracker(curSequence, baselinedetections)
%% tracker configuration
% THese were movied from the best results in Table 3 of the original paper for VIOU
%  using medianflow (exclusing one troublesome video).  We selected MedianFlow as it 
%  work better on fishtrac data and also mirrors more closelyt the approach used by RCT
sigma_l = curSequence.thre;  %Changed to better interact with the FISHTRAC harness - this is the harc
                            %  cutoff for detection confidence
sigma_h=0.5;  %CHanged frpm 0.98 to more closely match RCT and be more suitable for a low-performance setting
                % (very few predictions above 0.98!)
sigma_iou = 0.3;  % Changed to match KIOU's recommended value for fair comparison - this also works quite well on FISHTRAC darta and is a medium between the 0.1-0.2 values they use for VisDrone and the 0.5-0.6 values they use for UA-DETRAC
t_min=19; %Taken from the VIOU paper (Table 3)
ttl=10; % Taken from the VIOU paper (Table 3)
tracker_type='MEDIANFLOW';
keep_upper_height_ratio=1.0; %Default option

#sigma_p = 24;
#sigma_len = 3;
#skipframes = 0;
#skip_factor = 3;


global options
pythonPath = [options.condaPath  '/fish_env/bin/python'];


delete('results.mat');
detects = (baselinedetections(:).');
%disp('detects');
%disp(detects);
save -6 detections.mat detects;

disp("running tracking alg");
%% running tracking algorithm
try
	#method = [pythonPath ' octave_wrapper.py detections.mat ' num2str(sigma_l) ' ' num2str(sigma_iou) ' ' num2str(sigma_p) ' ' num2str(sigma_len) ' ' num2str(skipframes) ' ' num2str(skip_factor)]
	method = [pythonPath ' octave_wrapper.py detections.mat ' num2str(sigma_l) ' ' num2str(sigma_h) ' ' num2str(sigma_iou) ' ' num2str(t_min) ' ' num2str(ttl) ' ' tracker_type ' ' num2str(keep_upper_height_ratio) ' ' curSequence.seqName];
	
  system(method);
	load('results.mat');
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

