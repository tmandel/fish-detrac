function [midLevelTracklets, tracksSmooth, trackAll] = stitchTracklets(midLevelTracklets)

maxAllowdDist = 5;
% Loop Over All tracks 
for iTrack = 1:length(midLevelTracklets)-1
    oldTracklet = midLevelTracklets(iTrack);
    newTracklet = midLevelTracklets(iTrack+1);
    
    numOldTracklets = length(oldTracklet.bbox);
    numNewTracklets = length(newTracklet.bbox);
  
    if iTrack ==1
        midLevelTracklets(1,iTrack).IDS = 1:numOldTracklets;
        maxID = numOldTracklets;
    end    
    
    avg_spatial_dist = zeros(numNewTracklets, numOldTracklets);
    IDSNew = ones(1,numNewTracklets)*-1;
    for iNewTracklet = 1:numNewTracklets
        for iOldTracklet = 1:numOldTracklets
            frameMaxOld = max(oldTracklet.frames{iOldTracklet});
            frameMinNew = min(newTracklet.frames{iNewTracklet});
            if(frameMinNew>frameMaxOld)
                avg_spatial_dist(iNewTracklet, iOldTracklet)= Inf;
                continue;
            end
            
            % Find frame interesection between two tracklets
            [~, ia, ib] = intersect(oldTracklet.frames{iOldTracklet},newTracklet.frames{iNewTracklet});
            posOld = [(oldTracklet.bbox{iOldTracklet}(ia,1)+oldTracklet.bbox{iOldTracklet}(ia,3))/2, ...
                (oldTracklet.bbox{iOldTracklet}(ia,2)+oldTracklet.bbox{iOldTracklet}(ia,4))/2]';
            posNew = [(newTracklet.bbox{iNewTracklet}(ib,1)+newTracklet.bbox{iNewTracklet}(ib,3))/2, ...
                (newTracklet.bbox{iNewTracklet}(ib,2)+newTracklet.bbox{iNewTracklet}(ib,4))/2]';
            avg_spatial_dist(iNewTracklet, iOldTracklet) = norm(posNew-posOld)/length(ia);
            
        end
    end
    
    [val, ind] = min(avg_spatial_dist,[],2);
    [sortedVal, sortedInd] = sort(val);
    matchedIDS = [];
    
    for i = sortedInd'
        if(val(i)<maxAllowdDist)
            % Assoaciation
            matchedIDS = [matchedIDS, i];
            IDSNew(1, i)=midLevelTracklets(iTrack).IDS(ind(i));
        end
    end
    
    nonMatched = setdiff(1:numNewTracklets,matchedIDS);
    for i = nonMatched
        IDSNew(1,i)=maxID+1;
        maxID = maxID+1;
    end
    midLevelTracklets(iTrack+1).IDS = IDSNew; 
end

%% Interpolation 

tracks = cell(1,maxID);
for iTrack = 1:length(midLevelTracklets)
    for iTracklet = 1:length(midLevelTracklets(1,iTrack).bbox)
        currID    = midLevelTracklets(1,iTrack).IDS(iTracklet);
        currBox   = midLevelTracklets(1,iTrack).bbox{iTracklet};
        currFrame = midLevelTracklets(1,iTrack).frames{iTracklet};
        tracks{1, currID} = [tracks{1, currID}; currFrame currBox];  
    end
end

tracksSmooth = cell(1,length(tracks));
trackAll = zeros(100000,6);
counter = 1;
for iTrack = 1:length(tracks)
   currTrack = tracks{1, iTrack};
   [uniqueFrames, indUniqueFrames] = unique(currTrack(:,1));
   currTrack = currTrack(indUniqueFrames, :);
   minFrame = min(currTrack(:,1));
   maxFrame = max(currTrack(:,1));
   x1 = interp1(currTrack(:,1), currTrack(:,2), minFrame:maxFrame);
   y1 = interp1(currTrack(:,1), currTrack(:,3), minFrame:maxFrame);
   x2 = interp1(currTrack(:,1), currTrack(:,4), minFrame:maxFrame);
   y2 = interp1(currTrack(:,1), currTrack(:,5), minFrame:maxFrame);
   tracksSmooth{1,iTrack}=[(minFrame:maxFrame)', repmat(iTrack, maxFrame-minFrame+1,1), x1', y1', x2', y2'];
   trackAll(counter:(counter+maxFrame-minFrame),:)=tracksSmooth{1,iTrack};
   counter = counter + (maxFrame-minFrame+1);
end
trackAll(counter:end,:)=[];





