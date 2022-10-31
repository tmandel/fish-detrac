function options = initialize_environment()
%% initialize the parameters for MOT evaluation
% If you do not download the MAT annotation, you can generate them based on the XML annotation. 
% To avoid the "OutOfMemory" error, please set the Java memory as 1 GB in the path
% "home>preferences>general>java heap memory>" of the Matlab software before running.
% Note that each XML2MAT transformation spends tens of seconds.

%% input the path of the DETRAC benchmark
options.imgPath = './DETRAC-images/'; % the path of images
options.detPath = './DETRAC-Train-Detections/'; % the path of detections
options.gtPath = './DETRAC-Train-Annotations-MAT/'; % the path of annotations (e.g., XML, MAT)
options.seqPath = 'sequences.txt'; % the path of evaluated sequences
options.condaPath = '/home/dummy/.conda/envs'; %Appropriate conda environment

%% select the evaluation mode
% select the type of evaluation, i.e., Detection and Tracking
% If you select the 'Detection' type, the toolkit can show the detection curve and save the precision-recall result for the sequences in the DETRAC-Train set.
% If you select the 'Tracking' type, the toolkit can evaluate the tracker and save the tracking results for the sequences in the DETRAC-Train set.
options.evaluateType = 'Tracking';
% select the sequences for evaluation, i.e., DETRAC-Train, DETRAC-Test (DETRAC-Test-Beginner and DETRAC-Test-Experienced for AVSS2017 Challenge) and DETRAC-Free
options.evaluateSeqs = 'DETRAC-Train'; 
% select the type of detector, i.e., DPM, ACF, R-CNN and CompACT. Multiple detectors are welcomed.
options.detectorSet = {'R-CNN'}; 
% we conduct 2d evaluation for the DETRAC benchmark
options.track3d = false; 

% for "DETRAC-Free", detectionThreshold can be set as several thresholds, e.g, [0.1 0.2 0.5]
% or detectionThreshold should be set as 0:options.trackingThreStep:1.
options.trackingThreStep = 0.1;
%if options.metric is DETRAC-MOT then the following line will be overridden in trackingEvaluation.m(unless the threshold is set to a single number, rather than a range)
options.detectionThreshold = [0.3];%0.0:options.trackingThreStep:1.0;% the threshold of detection scores3
% the tracking metric: CLEAR-MOT or DETRAC-MOT
% For AVSS2017 Challenge, DETRAC-MOT is the only evaluation measure.
options.motmetric = 'DETRAC-MOT'; 

% evaluate the sequences in the whole DETRAC-train set
% Since the annotations of the DETRAC-train set are avaliable, you can print the evaluation results immediately.
if(strcmp(options.evaluateSeqs, 'DETRAC-Train'))
    options.printEvaluationForEachSeq = true; % if the groundtruth files are avalible, print the evaluation result for each sequence calculated by the CLEAR-MOT measure
    options.printEvaluationForWholeSet = false; % Gets the PR-MOTA and other PR metrics if the groundtruth files are avalible, print the evaluation result for all the evaluated sequences calculated by options.motmetric
    options.printDetectionEval = true; % if the groundtruth files are avalible, print the evaluation result for detection
    options.showDetectionCurve = true; % show the detection PR curve when using DETRAC-MOT measure    
    
% evaluate the sequences in the whole DETRAC-test set
% Since the annotations of the DETRAC-test set are not avaliable, we should comment the corresponding evaluation functions.
elseif(strcmp(options.evaluateSeqs, 'DETRAC-Test'))
    copyfile('evaluation/seqs/testlist-full.txt','sequences.txt'); % modify the evaluated sequences
    options.printEvaluationForEachSeq = false; % if the groundtruh files are avalible, print the evaluation result for each sequence calculated by the CLEAR-MOT measure
    options.printEvaluationForWholeSet = false; % if the groundtruh files are avalible, print the evaluation result for all the evaluated sequences calculated by options.motmetric
    options.printDetectionEval = false; % if the groundtruh files are avalible, print the evaluation result for detection
    options.showDetectionCurve = false; % show the detection PR curve when using DETRAC-MOT measure

% evaluate the "beginner" sequences in the DETRAC-test set
% Since the annotations of the DETRAC-test set are not avaliable, we should comment the corresponding evaluation functions.
elseif(strcmp(options.evaluateSeqs, 'DETRAC-Test-Beginner'))
    if(strcmp(options.evaluateType, 'Detection'))
        copyfile('evaluation/seqs/testlist-det-beginner.txt','sequences.txt'); % modify the evaluated sequences
    else        
        copyfile('evaluation/seqs/testlist-trk-beginner.txt','sequences.txt'); % modify the evaluated sequences
    end
    options.printEvaluationForEachSeq = false; % if the groundtruh files are avalible, print the evaluation result for each sequence calculated by the CLEAR-MOT measure
    options.printEvaluationForWholeSet = false; % if the groundtruh files are avalible, print the evaluation result for all the evaluated sequences calculated by options.motmetric
    options.printDetectionEval = false; % if the groundtruh files are avalible, print the evaluation result for detection    
    options.showDetectionCurve = false; % show the detection PR curve when using DETRAC-MOT measure
    
% evaluate the "experienced" sequences in the DETRAC-test set
% Since the annotations of the DETRAC-test set are not avaliable, we should comment the corresponding evaluation functions.
elseif(strcmp(options.evaluateSeqs, 'DETRAC-Test-Experienced'))
    if(strcmp(options.evaluateType, 'Detection'))    
        copyfile('evaluation/seqs/testlist-det-experienced.txt','sequences.txt'); % modify the evaluated sequences
    else
        copyfile('evaluation/seqs/testlist-trk-experienced.txt','sequences.txt'); % modify the evaluated sequences
    end 
    options.printEvaluationForEachSeq = false; % if the groundtruh files are avalible, print the evaluation result for each sequence calculated by the CLEAR-MOT measure
    options.printEvaluationForWholeSet = false; % if the groundtruh files are avalible, print the evaluation result for all the evaluated sequences calculated by options.motmetric
    options.printDetectionEval = false; % if the groundtruh files are avalible, print the evaluation result for detection    
    options.showDetectionCurve = false; % show the detection PR curve when using DETRAC-MOT measure    
    
% evaluate the sequences in the custom set
% If the user selects just one threshold of detection scores, the tracking metric should be CLEAR-MOT.    
elseif(strcmp(options.evaluateSeqs, 'DETRAC-Free'))
    % the tracking metric: CLEAR-MOT or DETRAC-MOT
    % if only one detectionThreshold is selected, DETRAC-MOT is not avalible. 
    if(length(options.detectionThreshold) == 1)
        disp('Warning: If only one detection score threshold is selected, the DETRAC-MOT measure is not avalible. We should employ the CLEAR-MOT measure.');     
        options.motmetric = 'CLEAR-MOT';
    end
    options.printEvaluationForEachSeq = true; % if the groundtruh files are avalible, print the evaluation result for each sequence calculated by the CLEAR-MOT measure
    options.printEvaluationForWholeSet = true; % if the groundtruh files are avalible, print the evaluation result for all the evaluated sequences calculated by options.motmetric
    options.printDetectionEval = true; % if the groundtruh files are avalible, print the evaluation result for detection    
    options.showDetectionCurve = true; % show the detection PR curve when using DETRAC-MOT measure
end

%% parameters for displaying visual results
options.showVisualResults = false; % show the visual tracking results
options.saveVisualResults = false; % save the visual tracking results
options.showRemoveResults = false; % show the removed tracking results in the ignored regions

options.displayDots = true; % display the trajectory dots
options.displayBoxes = true; % display the bounding box of the target
options.displayID = true; % display the ID of the target
options.displayCropouts = false; % display the border cropouts
options.displayConnections = false; % display the connection of the sample target    

%runExperiment();
%% verify the legitimacy of the parameters
options = checkOptions(options);
