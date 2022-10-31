function [errorMsg, realList] = checkResultFormat(unzipPath, detectorName)
%% Check detection format
global options

errorMsg = [];
HEIGHT = 540;
WIDTH = 960;

resList = dir(fullfile(unzipPath, '*.txt'));
disp(unzipPath);
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
realList = importdata(listPath, ',');

%% Check number%

%disp('realList');
%disp(realList);
%disp('resList');
%disp(resList);
if(length(resList) < length(realList))
    errorMsg = sprintf('Results must be %d txt files!', length(realList));
    return;
end

%% Check list
for i = 1:length(realList)
    fprintf('Checking %d/%d\n', i, length(realList));
    %disp(realList);
    resName = [realList{i} '_Det_' detectorName '.txt'];
    if(~exist([unzipPath resName], 'file'))
        errorMsg = sprintf('Sequence %s is not valid', resName);
    end        
    %% Check ext
    [~, namePart, nameExt] = fileparts(resName);
    if(~strcmp(nameExt, '.txt'))
        errorMsg = sprintf('%s must be txt file', resName);
        return;
    end
    %% Check resName format
    %pos = strfind(namePart, '_');
    %if(length(pos) ~= 3)
        %errorMsg = sprintf('%s must be MVI_XXX_Det_DetectorName.txt', resName);
        %return;
    %end
    %midName = namePart(pos(2)+1:pos(3)-1);
    %if(~strcmp(midName, 'Det'))
        %errorMsg = sprintf('%s must be MVI_XXX_Det_DetectorName.txt', resName);
        %return;
    %end
        
    %% Check content
    detections = load(fullfile(unzipPath, resName));
    lineCnt = 1;
    while(lineCnt <= size(detections, 1))
        content = detections(lineCnt, :);
        % each line of the file should be set as [Frame, Number, Left, Top, Width, Height, Score]
        if(length(content) ~= 7)
            errorMsg = sprintf('Content must be [Frame, Number, Left, Top, Width, Height, Score] (Line %d in %s)', lineCnt, resName);
            return;
        end
        frame = content(1);
        number = content(2);
        left = min(max(content(3), 1), WIDTH);
        top = min(max(content(4), 1), HEIGHT);
        width = min(content(5), WIDTH - left + 1);
        height = min(content(6), HEIGHT - top + 1);
        score = content(7);
        if (score < 0 || score > 1)
            errorMsg = sprintf('Score must be in [0, 1] (Line %d in %s)', lineCnt, resName);      
            return;
        end
        if(height <= 0)
            errorMsg = sprintf('Height must be postive (Line %d in %s)', lineCnt, resName);
            return;
        end
        if(width <= 0)
            errorMsg = sprintf('Width must be positive (Line %d in %s)', lineCnt, resName);
            return;
        end
        detections(lineCnt, :) = [frame, number, left, top, width, height, score];
        lineCnt = lineCnt + 1;
    end
	dlmwrite(fullfile(unzipPath, resName), detections);    
end