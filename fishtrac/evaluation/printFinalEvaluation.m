function printFinalEvaluation(res_path, detectorSet, folderName)

global options tracker

if(options.printEvaluationForWholeSet) 
    trackerName = tracker.trackerName;
    metricsInfo = getMetricInfo();
    curPath = pwd;
    %disp('pwd');
    %disp(pwd);
    cd('./evaluation');
    addpath(genpath('.'));
    for idDet = 1:length(detectorSet)
        detectorName = detectorSet{idDet};
        if(strcmp(options.motmetric, 'CLEAR-MOT'))
            % obtain CLEAR-MOT scores            
            clearmotLine = ['CLEAR_MOT_EVAL.exe ' trackerName ' ' detectorName ' ' curPath '/' res_path detectorName '/ ' ...
                            curPath '/thresh.txt ' curPath '/sequences.txt ' curPath '/' res_path detectorName '/'];                        
            %evalexe(clearmotLine);
            [status,b] = system(clearmotLine);      
            % print CLEAR-MOT scores
            for idThre = 1:length(folderName)
                motFile = [curPath '/' res_path detectorName '/' trackerName '_' detectorName '_CLEAR-MOT_results.txt'];
                metricsAll = load(motFile);
                %disp(['Tracker ' trackerName ' + Detector ' detectorName ' (Detection Score Threshold=' folderName{idThre} ') by CLEAR-MOT Evaluation:']);
                metrics = metricsAll(idThre, :);
                printMetrics(metrics, metricsInfo, 1);  
            end             
        elseif(strcmp(options.motmetric, 'DETRAC-MOT'))
            % obtain detection PR scores
            %disp('starting DETRAC-MOT');
            detprFile = [options.detPath detectorName '/' detectorName '_detection_PR.txt'];
            detprLine = ['DETRAC_DET_EVAL.exe ' detectorName ' ' options.detPath detectorName '/ ' curPath '/sequences.txt ' num2str(options.trackingThreStep) ' ' options.detPath detectorName '/'];
            %evalexe(detprLine);
            %disp('detprLine');
            %disp(detprLine);
            [status,b] = system(detprLine, ' ');
            %disp(status);
            if(exist(detprFile, 'file'))     
                disp('detection results!');      
                showDetectionPRCurve(detprFile, detectorName);
            else
                disp('no detection results!');
                error('no detection results!');
            end
            % obtain DETRAC-MOT scores
            %detracmotLine = ['DETRAC_MOT_EVAL.exe ' trackerName ' ' detectorName ' ' options.detPath detectorName '/' detectorName '_thres.txt '...
                             %curPath '/' res_path detectorName '/ ' curPath '/sequences.txt ' ... 
                             %curPath '/' res_path detectorName '/ ' options.detPath detectorName '/'];                      
            
            detracmotLine = ['DETRAC_MOT_EVAL.exe ' trackerName ' ' detectorName ' ' options.detPath detectorName '/' detectorName '_thres.txt '...
                             detprFile ' ' curPath '/sequences.txt ' ... 
                             curPath '/' res_path detectorName '/ ' curPath '/' res_path detectorName '/'];                         
            %evalexe(detracmotLine);       

            disp(detracmotLine);
            [status,b] = system(detracmotLine);       
            motFile = [curPath '/' res_path detectorName '/' trackerName '_' detectorName  '_DETRAC-MOT_results.txt'];
            %disp(motFile);
            if(exist(motFile, 'file'))
                %disp('tracking results!');
                temp = csvread(motFile);
                %disp('loaded motFile');
                metrics = temp(temp(:,1) == -1, 2:end);
                metricsInfo = getPRMetricInfo();
                %disp(['Tracker ' trackerName ' + Detector ' detectorName ' by DETRAC-MOT Evaluation:']);                
                padChar={' ',' ','|',' ',' ','|',' ',' ',' ','| ',' ',' ',' '};
                printMetrics(metrics, metricsInfo, 1, padChar);  
                %disp('printed metrics');            
            else
                disp('no tracking results!');
                error('no tracking results!');
            end
        end
    end
    cd('../');
end