function zipTrackingResults(trackerName, detectorName)

global options sequences

if(ismember(options.evaluateSeqs, {'DETRAC-Test', 'DETRAC-Test-Beginner', 'DETRAC-Test-Experienced'}))
    disp(['Saving tracking results in ' options.evaluateSeqs ' level...']);       
    resPath = ['results\' trackerName '\'];
    if(~isdir(resPath))
        mkdir(resPath);
    end       
    if(strcmp(options.motmetric, 'CLEAR-MOT'))
        if(~isdir([trackerName '\']))
            mkdir([trackerName '\']);
        end           
        disp([trackerName '+' detectorName '-->The evaluted thresholds are: ' num2str(options.detectionThreshold)]);
        thre = input('Please input one specific threshold of detection score to submit:\n');        
        flag = false;
        while(~ismember(thre, options.detectionThreshold))
            disp([trackerName '+' detectorName '-->The evaluted thresholds are: ' num2str(options.detectionThreshold)]);
            thre = input('Error in threshold! Please input again:\n');
            for k = 1:length(sequences)
                seqName = sequences{k}.seqName;                
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_LX.txt'], [trackerName '\' seqName '_LX.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_LY.txt'], [trackerName '\' seqName '_LY.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_W.txt'], [trackerName '\' seqName '_W.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_H.txt'], [trackerName '\' seqName '_H.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_speed.txt'], [trackerName '\' seqName '_speed.txt']);                
            end
            zip([date '_' trackerName '_' detectorName '_' options.evaluateSeqs '_CLEAR_tracking_results.zip'], [trackerName '\']);
            flag = true;
        end
        if(~flag)
            for k = 1:length(sequences)
                seqName = sequences{k}.seqName;
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_LX.txt'], [trackerName '\' seqName '_LX.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_LY.txt'], [trackerName '\' seqName '_LY.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_W.txt'], [trackerName '\' seqName '_W.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_H.txt'], [trackerName '\' seqName '_H.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_speed.txt'], [trackerName '\' seqName '_speed.txt']);               
            end
            zip([date '_' trackerName '_' detectorName '_' options.evaluateSeqs '_CLEAR_tracking_results.zip'], [trackerName '\']);
        end
    else      
        for thre = options.detectionThreshold
            if(~isdir([trackerName '\' sprintf('%.1f', thre) '\']))
                mkdir([trackerName '\' sprintf('%.1f', thre) '\']);
            end               
            for k = 1:length(sequences)
                seqName = sequences{k}.seqName;
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_LX.txt'], [trackerName '\' sprintf('%.1f', thre) '\' seqName '_LX.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_LY.txt'], [trackerName '\' sprintf('%.1f', thre) '\' seqName '_LY.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_W.txt'], [trackerName '\' sprintf('%.1f', thre) '\' seqName '_W.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_H.txt'], [trackerName '\' sprintf('%.1f', thre) '\' seqName '_H.txt']);
                copyfile([resPath detectorName '\' sprintf('%.1f', thre) '\' seqName '_speed.txt'], [trackerName '\' sprintf('%.1f', thre) '\' seqName '_speed.txt']);               
            end        
            zip([date '_' trackerName '_' detectorName '_' options.evaluateSeqs '_DETRAC_tracking_results.zip'], [trackerName '\']);    
        end
    end
    deleteFolder([trackerName '\']);    
    disp(['Tracking results in ' options.evaluateSeqs ' level are saved.']);   
end