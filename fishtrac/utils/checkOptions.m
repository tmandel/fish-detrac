function options = checkOptions(options)

global tracker

%% initial display
disp('************************************************************************************');
disp('*              Welcome to the UA-DETRAC MOT Toolkit v1.1!                          *');
disp('* This is the official detection/tracking evaluation kit for the DETection and     *'); 
disp('* tRACking (DETRAC) Benchmark (http://detrac-db.rit.albany.edu/).                  *');
disp('* More details can be found in the paper "UA-DETRAC: A New Benchmark and Protocol  *');
disp('* for Multi-Object Detection and Tracking".                                        *');
disp('*                 The UA-DETRAC Group @Copyright 2017                              *');
disp('************************************************************************************');

%% check command lines
if(nnz(ismember({'Detection','Tracking'},options.evaluateType)) == 0)
    error('error in type of evaluation!');
end
if(nnz(ismember({'DETRAC-Test','DETRAC-Test-Beginner','DETRAC-Test-Experienced','DETRAC-Train','DETRAC-Free'},options.evaluateSeqs)) == 0)
    error('error in sequences for evaluation!');
end
if(nnz(ismember({'DETRAC-MOT','CLEAR-MOT'},options.motmetric)) == 0)
    error('error in MOT metric!');
end

%% check the tracker for evaluation
if(strcmp(options.evaluateType, 'Tracking'))
    flagtracker = false;
    folders = dir('trackers/');  
    for i = 3:length(folders)
        nameFolds = folders(i).name; 
        if(ismember(tracker.trackerName, nameFolds))
            flagtracker = true;
            break;
        end
    end
    if(~flagtracker)
        error('error in the tracker name!');
    end
end

%% check the detector for evaluation
if(strcmp(options.evaluateType, 'Detection') || strcmp(options.evaluateType, 'Tracking'))
    flagdetector = true;
    folders = dir(options.detPath);
    nameFolds = [];
    for i = 3:length(folders)
        nameFolds{i-2} = folders(i).name; 
    end
    for j = 1:length(options.detectorSet)
        detectorName = options.detectorSet{j};
        if(nnz(ismember(detectorName, nameFolds))==0)
            flagdetector = false;
            break;
        end
    end
    if(~flagdetector)
        error('error in the detector name!');
    end
end

%% check the sequences for evaluation
if(false)
    fidTestSeq = fopen('evaluation/seqs/testlist-full.txt');
    testSeqs = [];
    idSeq = 0;
    while(~feof(fidTestSeq))
        % Data seqeunce
        seqName = fgetl(fidTestSeq);
        idSeq = idSeq + 1;
        testSeqs{idSeq} = seqName;
    end
    fclose(fidTestSeq);
    
    fidSeq = fopen(options.seqPath);
    while(~feof(fidSeq))
        % Data seqeunce
        seqName = fgetl(fidSeq);
        if(ismember(seqName, testSeqs))
            disp(['Warinig: the sequence ' seqName ' belongs to the DETRAC-test set, and no groundtruth files are avaliable!']);
            disp('The evaluation is not avaliable!');
            options.printEvaluationForEachSeq = false; % if the groundtruh files are avalible, print the evaluation result for each sequence calculated by the CLEAR-MOT measure
            options.printEvaluationForWholeSet = false; % if the groundtruh files are avalible, print the evaluation result for all the evaluated sequences calculated by options.motmetric
            options.printDetectionEval = false; % if the groundtruh files are avalible, print the evaluation result for detection                
            options.showDetectionCurve = false; % show the detection PR curve when using DETRAC-MOT measure    
        end
    end
    fclose(fidSeq);
end

%% check the mot metric
if(numel(options.detectionThreshold) == 1 && strcmp(options.motmetric, 'DETRAC-MOT'))
    disp('Waring: If only one detection score threshold is selected, the DETRAC-MOT measure is not avalible. We should employ the CLEAR-MOT measure.'); 
    options.motmetric = 'CLEAR-MOT';
end
