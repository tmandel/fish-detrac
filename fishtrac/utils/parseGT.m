function gtInfo = parseGT(gtFile, imgHeight, imgWidth, frameNums)
%% parse the ground truth

% first determine the type
[pathstr, filename, fileext] = fileparts(gtFile);
pathstr_mat = [pathstr(1:end-3) 'MAT'];
createPath(pathstr_mat);
% is there a .mat file available?
matfile = fullfile(pathstr_mat, [filename '.mat']);
if(exist(matfile,'file'))
    % check for the variable gtInfo
    fileInfo = who('-file', matfile);
    varExists = 0; 
    cnt = 0;
    while(~varExists && cnt<length(fileInfo))
        cnt = cnt+1;
        varExists = strcmp(fileInfo(cnt),'gtInfo');
    end
    if(varExists)
        load(matfile, 'gtInfo');
    else
        warning('Specified file does not contained correct ground truth.');
    end
    
elseif(strcmpi(fileext,'.xml')) % txt
    disp(['parsing the XML annotation of sequence ' filename '...']);
    structData = xml2struct(gtFile);
    [gt, occ, ignoreRegion] = struct2gt(structData);
    gt = sortrows(gt, 6); % sort the groudtruth by the target IDs
    gt = max(1,round(gt)); % the position value is counted starting from 1
    %% remove trajectories in ignored region
    if(~isempty(ignoreRegion))
        igrMap = zeros(imgHeight, imgWidth);
        numIgnore = size(ignoreRegion, 1);

        for j = 1:numIgnore
            igrMap(ignoreRegion(j,2):min(imgHeight,ignoreRegion(j,2)+ignoreRegion(j,4)),ignoreRegion(j,1):min(imgWidth,ignoreRegion(j,1)+ignoreRegion(j,3))) = 1;
        end
        intIgrMap = createIntImg(double(igrMap));
        objectID = unique(gt(:,6));
        idxLeft = [];
        for i = 1:numel(objectID)
            curTrk = find(gt(:,6) == objectID(i));
            curDet = gt(curTrk,1:4);
            curLine = [];
            for j = 1:size(curDet,1)
                x = curDet(j,1);
                y = curDet(j,2);
                w = curDet(j,3);
                h = curDet(j,4);
                tl = intIgrMap(y, x);
                tr = intIgrMap(y, min(imgWidth,x+w));
                bl = intIgrMap(min(imgHeight,y+h), x);
                br = intIgrMap(min(imgHeight,y+h), min(imgWidth,x+w));
                ignoreValue = tl + br - tr - bl; 
                if(ignoreValue/(h*w)<0.5)
                    curLine = cat(1, curLine, curTrk(j));
                end
            end
            minLine = min(curLine);
            maxLine = max(curLine);
            idxLeft = cat(2, idxLeft, minLine:maxLine);
        end
        gt = gt(idxLeft, :);   
    end
   %% now parse  
    gtInfo = [];
    leftIDs = unique(gt(:,6));
    for t = frameNums
        idx = find(gt(:,5) == t);
        gtInfo.X(t,1)=0;       
        gtInfo.Y(t,1)=0;
        gtInfo.H(t,1)=0;
        gtInfo.W(t,1)=0;                
        for i = 1:numel(idx)
            w = gt(idx(i), 3);
            h = gt(idx(i), 4);
            xc = gt(idx(i), 1) + w/2;
            yc = gt(idx(i), 2) + h/2;
            [~, id] = ismember(gt(idx(i), 6), leftIDs);
            % foot position
            gtInfo.X(t,id)=xc;       
            gtInfo.Y(t,id)=yc+h/2;
            gtInfo.H(t,id)=h;
            gtInfo.W(t,id)=w;
        end
    end           
    gtInfo.frameNums = frameNums;
    matfile = fullfile(pathstr_mat,[filename '.mat']);
    save(matfile, 'gtInfo');
else
    error('wrong format of gorund truth files!');       
end 