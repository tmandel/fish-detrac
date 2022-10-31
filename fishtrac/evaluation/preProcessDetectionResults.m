function preProcessDetectionResults(detectorName)

global options sequences

optionID = find(ismember({'DETRAC-Test','DETRAC-Train','DETRAC-Free','DETRAC-Test-Beginner','DETRAC-Test-Experienced'},options.evaluateSeqs));
if(optionID == 1)
    listPath  = 'seqs/testlist-full.txt';
elseif(optionID == 2)
    listPath  = 'seqs/trainlist-full.txt';
elseif(optionID == 3)
    listPath = '../sequences.txt';
elseif(optionID == 4)
    listPath  = 'seqs/testlist-det-beginner.txt';
elseif(optionID == 5)
    listPath  = 'seqs/testlist-det-experienced.txt';    
else
    error('error in sequences for evaluation!');
end

%% calculate the minimal and maximal detection scores
disp('pre-processing the detection results...');
createNewPath([options.detPath detectorName '/' ]);
fidSeq = fopen(listPath);
idSeq = 0;
scores = [];
while(~feof(fidSeq))
    idSeq = idSeq + 1;
    % Data sequence
    seqName = fgetl(fidSeq);
    oldPath = [options.detPath detectorName '/' seqName '_Det_' detectorName '.txt'];
    tmpPath = [options.detPath detectorName '/' seqName '_Det_' detectorName '.txt'];
    if(~exist(oldPath, 'file'))
        disp(['missing detection result for sequence' seqName '!']);
    end
    detections = load(oldPath);
    scores = cat(1,scores,detections(:,end));
    movefile(oldPath,tmpPath);
end
fclose(fidSeq);

minScore = min(scores);
maxScore = max(scores);

%% normlized the detection scores and move the invalid detections
createPath([options.detPath detectorName '/']); 
fidSeq = fopen(listPath);
idSeq = 0;
while(~feof(fidSeq))
    idSeq = idSeq + 1;
    % Data sequence
    seqID = fgetl(fidSeq);
    seqName = seqID(end-8:end);
    oldPath = [options.detPath detectorName '/' seqName '_Det_' detectorName '.txt'];
    newPath = [options.detPath detectorName '/' seqName '_Det_' detectorName '.txt'];
    detections = load(oldPath);
    norm_detections = detections;
    scores_ = (detections(:,end)-minScore)/(maxScore-minScore);
    norm_detections = cat(2, norm_detections(:,1:end-1), scores_);
    
    ignoreFile = ['igrs/' seqID '_IgR.txt'];
    imgHeight = sequences{idSeq}.imgHeight;
    imgWidth = sequences{idSeq}.imgWidth;
    cutdetections = dropDetections(norm_detections, ignoreFile, imgHeight, imgWidth);  
    fr = unique(cutdetections(:,1));
    for k = 1:numel(fr)
        curLine = find(cutdetections(:,1) == fr(k));
        cutdetections(curLine,2) = 1:numel(curLine);
    end
    dlmwrite(newPath, cutdetections);
end