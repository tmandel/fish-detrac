%% SMOT detection data converter
clc, clear;
addpath('smot_util\');
datasetPath = 'smot_data\';
seqName = 'slalom';
format = '.txt';
seqPath = [datasetPath '\' seqName '\img'];
itlName = [datasetPath '\' seqName '\' seqName '.itl'];
savePath = [datasetPath '\' seqName '\' seqName format ];


% SMOT dataset 
if ~isempty(strfind(['dribbling,slalom,juggling,crowd,acrobats,firebirds,seagulls,balls,tud-crossing,tud-campus'],seqName))
    % get the information about the sequence
    itlData = loaditl(itlName);
end

% Convert to the detection results.
itlData = itl2idl(itlData);

% Open the detection saving files.
fid = fopen(savePath, 'w+');

nCount = 0;

% Data size
[~,nitem] = size(itlData);
% Save the detections.
for fr = 1:nitem
    dets = itlData(1,fr).rect;
    [nbox, ~] = size(dets);
    for n = 1:nbox;
        if nCount < 10
            % Print number of detections.
            fprintf(fid, '0000');
            fprintf(fid, '%d,', nCount);
        elseif nCount < 100 && nCount >= 10
            fprintf(fid, '000');
            fprintf(fid, '%d,', nCount);
        elseif nCount < 1000 && nCount >= 100
            fprintf(fid, '00');
            fprintf(fid, '%d,', nCount);
        elseif nCount < 10000 && nCount >= 1000
            fprintf(fid, '0');
            fprintf(fid, '%d,', nCount);
        end
        
        fprintf(fid, '%d,', fr);
        % left,top,right,bottom
        fprintf(fid, '%f,%f,%f,%f',dets(n,1),dets(n,2),dets(n,1)+dets(n,3)/2,dets(n,2)+dets(n,4)/2);
        fprintf(fid, '\n');
        nCount = nCount + 1;
    end
end
fclose(fid);