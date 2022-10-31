function trackingEvaluation()

global options sequences tracker

trackerName = tracker.trackerName; % the tracker name
detectorSet = options.detectorSet; % the detector set
detPath = options.detPath; % detection path
scoreSet = options.detectionThreshold; % detectionThreshold of detection scores
folderName = parseFolderName(scoreSet); % folders of tracking results in different detectionThreshold
res_path = ['results/' trackerName '/']; % tracking results saving path
createPath(res_path);

% Debug Logs
log_path = './logs/';
createPath(log_path);
diary([log_path 'DETRAC_' trackerName '_tracking_logs.txt']);    


for idSeq = 1:length(sequences)
    % Sequence Info
    seqName = sequences{idSeq}.seqName;
    curSequence = sequences{idSeq};
    gtInfo = curSequence.gtInfo;

    % Detector
    for idDet = 1:length(detectorSet)
        detectorName = detectorSet{idDet};
        disp(['Tracker ' trackerName ' + Detector ' detectorName '-->processing sequence ' num2str(idSeq) '/' num2str(length(sequences)) '...']);
        detFile = [detPath detectorName '/' seqName '_Det_' detectorName '.txt']; % detection file  
        disp(detFile);
        detections = loadDetections(detFile); % load detections
       %% evaluate the tracker under each detections configuration
        for idThre = 1:length(scoreSet)
           %% parse detection
            trackingResultSavePath = [res_path detectorName '/' folderName{idThre} '/'] ; % the path of tracking results
            createPath(trackingResultSavePath);
            resultSavePath = [trackingResultSavePath seqName];
            if(exist([resultSavePath '_LX.txt'], 'file') && exist([resultSavePath '_LY.txt'], 'file')&&...
                exist([resultSavePath '_W.txt'], 'file') && exist([resultSavePath '_H.txt'], 'file') && exist([resultSavePath '_speed.txt'], 'file'))               
                stateInfo = txt2stateInfo(resultSavePath, curSequence.frameNums); % geneate the state info
                printSeqEvaluation(seqName, gtInfo, stateInfo, folderName{idThre}); % print evaluation for each sequence
                showResults(stateInfo, curSequence, resultSavePath); % display visual results for each sequence                
                continue;
            end    
            idxDetections = find(detections(:,7) >= scoreSet(idThre));
            if(~isempty(idxDetections))
                baselinedetections = genCutDetections(detections, idxDetections);
            else
                saveEmptyResults(resultSavePath);                 
                continue;
            end

           %% run the tracker
            try
                % add the toolbox path
                cd(['./trackers/' trackerName]);
                addpath(genpath('.'));
                % run the tracker
                [stateInfo, speed] = run_tracker(curSequence, baselinedetections);
                % remove the toolbox path
                rmpath(genpath('.'));
                cd('../../');                 
            catch err
                % remove the toolbox path
                rmpath(genpath('./'));
                cd('../../');
                error('error in running the tracking method!');
            end
            printSeqEvaluation(seqName, gtInfo, stateInfo, folderName{idThre}); % print evaluation for each sequence          
            showResults(stateInfo, curSequence, resultSavePath); % display visual results for each sequence 
            saveResults(resultSavePath, stateInfo, speed); % save tracking results for each sequence
        end % end for detection score thresholds
    end % end for detectors
end % end for sequences

%% zip the tracking results for DETRAC-Test
zipTrackingResults(tracker.trackerName);

%% print final evaluation for all the selected sequences
printFinalEvaluation(res_path, detectorSet, folderName);