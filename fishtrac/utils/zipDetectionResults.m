function zipDetectionResults(detectorSet, realList)

global options

if(ismember(options.evaluateSeqs, {'DETRAC-Test', 'DETRAC-Test-Beginner', 'DETRAC-Test-Experienced'}))
    disp(['Saving detection results in ' options.evaluateSeqs ' level...']);       
    for idDet = 1:length(detectorSet) 
        detectorName = detectorSet{idDet};
        resPath = [detectorName '\'];
        if(~isdir(resPath))
            mkdir(resPath);
        end
        for k = 1:length(realList)
            resname = [realList{k} '_Det_' detectorName '.txt']; 
            copyfile([options.detPath detectorName '/' resname], [resPath resname]);
        end
        zip([date '_' detectorName '_' options.evaluateSeqs '_detection_results.zip'], [resPath '*.txt']);  
        deleteFolder(resPath);    
    end
    disp(['Detection results in ' options.evaluateSeqs ' level are saved.']);
end