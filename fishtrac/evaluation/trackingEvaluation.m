function trackingEvaluation()

global options sequences tracker

trackerName = tracker.trackerName; % the tracker name
detectorSet = options.detectorSet; 
detPath = options.detPath; % detection path
%if(strcmp(options.motmetric, 'DETRAC-MOT')) %Took this out so thresh is handled at higher level
    %scoreSet = 0.0:options.trackingThreStep:1.0; 
%else
scoreSet = options.detectionThreshold; 
%end
folderName = parseFolderName(scoreSet); % folders of tracking results in different detectionThreshold

res_path = ['results/' trackerName '/']; % tracking results saving path
disp("resPath:")
%disp(res_path)
%confirm_recursive_rmdir(0);
%rmdir(res_path,'s');%added so that trackers actually re-run

%createPath(res_path);
disp(options.detectionThreshold)
% Debug Logs
log_path = './logs/';
createPath(log_path);
diary([log_path 'DETRAC_' trackerName '_tracking_logs.txt']);    

for idDet = 1:length(detectorSet)
    detectorName = detectorSet{idDet};
    allSpeed = [];    
    for idSeq = 1:length(sequences)
        % Sequence Info
        seqName = sequences{idSeq}.seqName;
        curSequence = sequences{idSeq};
        curSequence.trackDuringOcclusion = getAnnotationStyle(seqName);
        gtInfo = curSequence.gtInfo;
        allMetrics = [];
        allAdditionalInfo = [];

        %disp(['Tracker ' trackerName ' + Detector ' detectorName '-->processing sequence ' num2str(idSeq) '/' num2str(length(sequences)) '...']);
        detFile = [detPath detectorName '/' seqName '_Det_' detectorName '.txt']; % detection file  
        detections = loadDetections(detFile); % load detections
       %% evaluate the tracker under each detections configuration
        for idThre = 1:length(scoreSet)
           %% parse detection
            disp('creating results path');
            
            trackingResultSavePath = [res_path detectorName '/' folderName{idThre} '/'] ; % the path of tracking results
            createPath(trackingResultSavePath);
            resultSavePath = [trackingResultSavePath seqName];
            disp('checking for existing results');
            if(exist([resultSavePath '_LX.txt'], 'file') && exist([resultSavePath '_LY.txt'], 'file')&&...
                exist([resultSavePath '_W.txt'], 'file') && exist([resultSavePath '_H.txt'], 'file') && exist([resultSavePath '_speed.txt'], 'file'))              
                disp('Results already exist for this tracker, sequence, threshold combination. Please remove old LX, LY, LW, LH results from "results/tracker/detector/thresh", and remove additional_info and mot_results in "results/tracker/detector" -- exiting...')
                error('Results already exist for this tracker, sequence, threshold combination. Please remove old LX, LY, LW, LH results from "results/tracker/detector/thresh", and remove additional_info and mot_results in "results/tracker/detector" -- exiting...')
            end    
            idxDetections = find(detections(:,7) >= scoreSet(idThre)); %
            %disp('idx');
            %disp(idxDetections);
            disp('checking for empty detections');
            if(~isempty(idxDetections))
                baselinedetections = genCutDetections(detections, idxDetections);
            else
                disp('No detections above this threshold');
                saveResultsNoDetections(resultSavePath);                 
                exit(1);
            end
            curSequence.thre = scoreSet(idThre);
            curSequence.detections = detections; % Hack, added to allow 
                                      %full detection info to be passed to 
                                      %tracker
          
            %run the tracker
            %try
                % add the toolbox path
            cd(['./trackers/' trackerName]);
            savepath('temp.pth')
            addpath(genpath('.'));
            
            disp('ABout to run tracker');
            tic
            % run the tracker
            [stateInfo, speed] = run_tracker(curSequence, baselinedetections);
            toc
            
            % remove the toolbox path
            rmpath(genpath('.'));
            source('temp.pth');
            cd('../../'); 
            trackerTimedOut = 0;
            if(~isfield(stateInfo, 'X'))
              %%%Mark should save off an empty stateInfo struct instead of exiting loop
                disp('WARNING: Tracker did not produce any tracks...');
                stateInfo = saveEmptyStateInfo(numel(gtInfo.frameNums));
                trackerTimedOut=1;
            end

            stateInfo = dropTracks(stateInfo, curSequence); % drop the trajectories in the ignored regions            
            [metrics, additionalInfo, metricsInfo] = printSeqEvaluation(seqName, gtInfo, stateInfo, folderName{idThre}); 
            showResults(stateInfo, curSequence, resultSavePath); % display visual results for each sequence 

            disp('calling saveresults!')
            saveResults(resultSavePath, stateInfo, speed); % save tracking results for each sequence

            allMetrics = cat(1, allMetrics, [scoreSet(idThre), metrics]);
            trackerFailed = 0;
            allAdditionalInfo = additionalInfo;
            disp('all additional info');
            disp(allAdditionalInfo);
            disp(fieldnames(allAdditionalInfo));
            allAdditionalInfo.thresh=scoreSet(idThre);
            allAdditionalInfo.timeout=trackerTimedOut;
            allAdditionalInfo.failure=trackerFailed;

            speed = load([resultSavePath '_speed.txt']);
            if(~isempty(speed))
                allSpeed = cat(1,allSpeed, speed);
            end                      
        end % end for detection score thresholds
        if(options.printEvaluationForEachSeq)

            additionalInfoHeader = [fieldnames(allAdditionalInfo)];
            %additionalInfoHeader = transpose(additionalInfoHeader);
            additionalInfoFileName = ['./trackers/' trackerName '/clear-mot/additional_info.txt'];

            % write additional info header
            disp(additionalInfoHeader)
            fileID = fopen(additionalInfoFileName,'w')
            headerIndices = 1:length(additionalInfoHeader) - 1;
            for m=headerIndices
                fprintf(fileID, '%s,', char(additionalInfoHeader(m)));
            end
            fprintf(fileID, '%s\n', char(additionalInfoHeader(length(additionalInfoHeader))));
            fclose(fileID);
            
            % write clear mot additional info
            disp('field names successfully called')
            additionalInfoResult = [struct2cell(allAdditionalInfo)];
            additionalInfoResult = cell2mat(transpose(additionalInfoResult));
            dlmwrite(additionalInfoFileName, additionalInfoResult, "-append");

            % Add new mot metric reults to mot result file
            motResultFileName = [res_path detectorName '/' seqName '_mot_result.txt'];
            dlmwrite(motResultFileName, allMetrics, "-append");

        end
    end % end for sequences
    if(options.printEvaluationForEachSeq)
        dlmwrite([res_path detectorName '/' trackerName '_speed.txt'], mean(allSpeed));  
    end
end % end for detectors

%% print final evaluation for all the selected sequences
printFinalEvaluation(res_path, detectorSet, folderName);

%% zip the tracking results for DETRAC-Test
for idDet = 1:length(detectorSet)
    detectorName = detectorSet{idDet};
    zipTrackingResults(tracker.trackerName, detectorName);   
end
