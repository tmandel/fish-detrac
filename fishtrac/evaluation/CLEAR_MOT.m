function [metrics, metricsInfo, additionalInfo] = CLEAR_MOT(gtInfo,stateInfo)
% compute CLEAR MOT and other metrics
%
% metrics contains the following
% [1]   recall	- recall = percentage of detected targets
% [2]   precision	- precision = percentage of correctly detected targets
% [3]   FAR		- number of false alarms per frame
% [4]   GT        - number of ground truth trajectories
% [5-7] MT, PT, ML	- number of mostly tracked, partially tracked and mostly lost trajectories
% [8]   falsepositives- number of false positives (FP)
% [9]   missed        - number of missed targets (FN)
% [10]  idswitches	- number of id switches     (IDs)
% [11]  FRA       - number of fragmentations    (FM)
% [12]  MOTA	- Multi-object tracking accuracy in [0,100]
% [13]  MOTP	- Multi-object tracking precision in [0,100] (3D) / [td,100] (2D)
% [14]  MOTAL	- Multi-object tracking accuracy in [0,100] with log10(idswitches)
%
%Additional info keys:
%------------------------------
%1)missed = FN
%2)falsepositives
%3)id switches
%4)sumg = GT total = TP + FN
%5)Nc = Number correct(total number of matches)
%6)Fgt = Frames in Ground Truth
%7)Ngt = MT+PT+ML(Number of ground truth trajectories)
%8)MT = mostly tracked
%9)PT = partially tracked
%10)ML = mostly lost
%11)FRA = trajectory fragmentations
%12)sumDists = total distances from bounding box to ground truth
%13)'Timeouts'
%14)'Failures'
%-------------------------------
%
%
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.


% default options: 2D
options.eval3d = false;   % only bounding box overlap
options.evalIOU = false;
options.evalDIOU = true; %mark

if options.evalIOU
  options.td = 0.7;      % threshold 70%
  factor = 0.8;
elseif options.evalDIOU 
  factor = 1.2;
  options.td = 1.25;%mark
else
  options.td = 3; 
  factor = 1.25;   
end

td = options.td;
%disp('stateInfo');
%disp(stateInfo.frameNums);
%disp('gtInfo');
%disp(gtInfo.frameNums);
assert(length(gtInfo.frameNums)==length(stateInfo.frameNums), ...
    'Ground Truth and state must be of equal length');
if(gtInfo.frameNums(1)~=stateInfo.frameNums(1))
    gtInfo.frameNums = gtInfo.frameNums + stateInfo.frameNums(1) - gtInfo.frameNums(1);
end
disp(gtInfo.frameNums)
assert(all(gtInfo.frameNums==stateInfo.frameNums), ...
    'Ground Truth and state must contain equal frame numbers');
%disp(stateInfo);
% check if all necessery info is available
if options.eval3d
    assert(all(isfield(gtInfo,{'Xgp','Ygp'})), ...
        'Ground Truth Ground Plane coordinates needed for 3D evaluation');
    assert(all(isfield(stateInfo,{'Xgp','Ygp'})), ...
        'Ground Plane coordinates needed for 3D evaluation');
else
    assert(all(isfield(gtInfo,{'X','Y','W','H'})), ...
        'Ground Truth coordinates X,Y,W,H needed for 2D evaluation');
    assert(all(isfield(stateInfo,{'Xi','Yi','W','H'})), ...
        'State coordinates Xi,Yi,W,H needed for 2D evaluation');
    
end

gtInd=~~gtInfo.X;
stInd=~~stateInfo.X;

[Fgt, Ngt]=size(gtInfo.X);
disp('stateInfo.X size:')
disp(size(stateInfo.X))
[F, N]=size(stateInfo.X);
aspectRatio=mean(gtInfo.W(~~gtInfo.W)./gtInfo.H(~~gtInfo.H));

%disp('X size: ')
%disp(size(stateInfo.X))
%disp('Xi size: ')
%disp(size(stateInfo.Xi))
%disp('W size')
%disp(size(stateInfo.X))


metricsInfo.names.long = {'Recall','Precision','False Alarm Rate', ...
    'GT Tracks','Mostly Tracked','Partially Tracked','Mostly Lost', ...
    'False Positives', 'False Negatives', 'ID Switches', 'Fragmentations', ...
    'MOTA','MOTP', 'MOTA Log'};

metricsInfo.names.short = {'Rcll','Prcn','FAR', ...
    'GT','MT','PT','ML', ...
    'FP', 'FN', 'IDs', 'FM', ...
    'MOTA','MOTP', 'MOTAL'};

metricsInfo.widths.long = [6 9 16 9 14 17 11 15 15 11 14 5 5 8];
metricsInfo.widths.short = [5 5 5 3 3 3 3 4 4 3 3 5 5 5];

metricsInfo.format.long = {'.1f','.1f','.2f', ...
    'i','i','i','i', ...
    'i','i','i','i', ...
    '.1f','.1f','.1f'};

metricsInfo.format.short=metricsInfo.format.long;


metrics=zeros(1,14);
metrics(9)=numel(find(gtInd));  % False Negatives (missed)
metrics(7)=Ngt;  % Mostly Lost
% nothing to be done, if state is empty
additionalInfo = [numel(find(gtInd)), 0, 0, numel(find(gtInd)), 0, numel(gtInfo.frameNums), Ngt, 0, 0, Ngt, 0, 0];

if ~N, disp('state is empty'); return; end

% mapping
M=zeros(F,Ngt);

mme=zeros(1,F); % ID Switchtes (mismatches)
c=zeros(1,F);   % matches found
fp=zeros(1,F);  % false positives
m=zeros(1,F);   % misses = false negatives
g=zeros(1,F);
d=zeros(F,Ngt);  % all distances;
if options.evalIOU
  ious=Inf*ones(F,Ngt);  % all overlaps
else
  ious=-Inf*ones(F,Ngt);  % all overlaps
end

matched=@matched2d;
if options.eval3d
  matched=@matched3d
end

alltracked=zeros(F,Ngt);
allfalsepos=zeros(F,N);

for t=1:F
    
    g(t)=numel(find(gtInd(t,:)));
    
    % mapping for current frame
    if t>1 % time step, frame number 
        mappings=find(M(t-1,:));
        for map=mappings
          %disp("check in evalIOU 1");
          %keyboard
          %This is what's killing us
            if gtInd(t,map) && stInd(t,M(t-1,map)) && matched(gtInfo,stateInfo,t,map,M(t-1,map),td*factor, options)
                M(t,map)=M(t-1,map);
            end
        end
    end
    
    GTsNotMapped=find(~M(t,:) & gtInd(t,:));
    EsNotMapped=setdiff(find(stInd(t,:)),M(t,:));
    
    if options.eval3d      
        cost = zeros(numel(GTsNotMapped), numel(EsNotMapped));
        for o = 1:numel(GTsNotMapped)
           GT = [gtInfo.Xgp(t,GTsNotMapped(o)), gtInfo.Ygp(t,GTsNotMapped(o))];
           for e = 1:numel(EsNotMapped)
               E = [stateInfo.Xgp(t,EsNotMapped(e)), stateInfo.Ygp(t,EsNotMapped(e))];
               cost(o,e)=norm(GT-E);
           end
        end 
        %disp("check in evalIOU 2");
        if options.evalIOU
          cost(cost > td) = Inf;
        else
          cost(cost < td) = -Inf;
        end
        assignLabel = munkres(cost);
        for i = 1:numel(assignLabel)
            if(assignLabel(i))
                M(t, GTsNotMapped(i)) = EsNotMapped(assignLabel(i));
            end
        end    

    else
        if options.evalIOU
             allisects=zeros(Ngt,N);     
        else
             allisects=ones(Ngt,N)* (td+1); %bigger than td
        end
        goodMax = true;
    
        while goodMax && numel(GTsNotMapped)>0 && numel(EsNotMapped)>0
            for o=GTsNotMapped
                GT=[gtInfo.X(t,o)-gtInfo.W(t,o)/2 ...
                    gtInfo.Y(t,o)-gtInfo.H(t,o) ...
                    gtInfo.W(t,o) gtInfo.H(t,o) ];
                for e=EsNotMapped
                    E=[stateInfo.Xi(t,e)-stateInfo.W(t,e)/2 ...
                        stateInfo.Yi(t,e)-stateInfo.H(t,e) ...
                        stateInfo.W(t,e) stateInfo.H(t,e) ];
                    %disp("check in evalIOU 3");
                    if (options.evalIOU)
                      allisects(o,e)=boxiou(GT(1),GT(2),GT(3),GT(4),E(1),E(2),E(3),E(4));
                    elseif (options.evalDIOU)
                      allisects(o,e)=boxdiou(GT(1),GT(2),GT(3),GT(4),E(1),E(2),E(3),E(4));%mark
                    else
                      allisects(o,e)=boxdist(GT(1),GT(2),GT(3),GT(4),E(1),E(2),E(3),E(4));
                     
                    end

                end
            end
            %disp("GTs not mapped");
            %disp(GTsNotMapped);
            %disp("Es not mapped");
            %disp(EsNotMapped);
            
            %disp("allisects");
            %disp(allisects(2,4));
            if options.evalIOU
              [maxisect, cind]=max(allisects(:));
            else
              [maxisect, cind]=min(allisects(:));
            end
            
            goodMax2 = false;
            %disp("check in evalIOU 4");
            
            if options.evalIOU
               if maxisect >= td
                 goodMax2 = true;
               end
            else
               if maxisect <= td
                 goodMax2 = true;
               end
            end   
                                   
            if goodMax2
                [u, v]=ind2sub(size(allisects),cind);
                %disp('goodMax2, matching gt=');
                %disp(u);
                %disp("to e=");
                %disp(v);
                %keyboard;
                M(t,u)=v;
                if options.evalIOU
                  allisects(:,v)=0;
                else
                   allisects(:,v)=td+1;
                end
                GTsNotMapped=find(~M(t,:) & gtInd(t,:));
                EsNotMapped=setdiff(find(stInd(t,:)),M(t,:));
            end
            
            goodMax = false;
            %%disp("check in evalIOU 5");
            %disp(options.evalIOU);
            if options.evalIOU
               if maxisect > td
                 goodMax = true;
               end
            else
               if maxisect < td
                 goodMax = true;
               end
            end  
            %disp("loop control vars")
            %disp(goodMax) 
            %disp(numel(GTsNotMapped))
            %disp(numel(EsNotMapped))
        end
      
    end
    %disp ("OUT OF LOOOP!")
    curtracked=find(M(t,:));
    
    alltrackers=find(stInd(t,:));
    mappedtrackers=intersect(M(t,find(M(t,:))),alltrackers);
    falsepositives=setdiff(alltrackers,mappedtrackers);
    
    alltracked(t,:)=M(t,:);
    allfalsepos(t,1:length(falsepositives))=falsepositives;
    
    %%  mismatch errors
    if t>1
        for ct=curtracked
            lastnotempty=find(M(1:t-1,ct),1,'last');
            if gtInd(t-1,ct) && ~isempty(lastnotempty) && M(t,ct)~=M(lastnotempty,ct)
                mme(t)=mme(t)+1;
            end
        end
    end
    %disp("curtracked is");
    %disp(curtracked);
    %keyboard;
    
    c(t)=numel(curtracked);
    for ct=curtracked
        eid=M(t,ct);
        if options.eval3d
            d(t,ct)=norm([gtInfo.Xgp(t,ct) gtInfo.Ygp(t,ct)] - ...
                [stateInfo.Xgp(t,eid) stateInfo.Ygp(t,eid)]);
        else
            gtLeft=gtInfo.X(t,ct)-gtInfo.W(t,ct)/2;
            gtTop=gtInfo.Y(t,ct)-gtInfo.H(t,ct);
            gtWidth=gtInfo.W(t,ct);    
            gtHeight=gtInfo.H(t,ct);
            
            stLeft=stateInfo.Xi(t,eid)-stateInfo.W(t,eid)/2;
            stTop=stateInfo.Yi(t,eid)-stateInfo.H(t,eid);
            stWidth=stateInfo.W(t,eid);    
            stHeight=stateInfo.H(t,eid);
            %disp("check in evalIOU 6");
            if (options.evalIOU)
              ious(t,ct)=boxiou(gtLeft,gtTop,gtWidth,gtHeight,stLeft,stTop,stWidth,stHeight);
            elseif(options.evalDIOU)
              ious(t,ct)=boxdiou(gtLeft,gtTop,gtWidth,gtHeight,stLeft,stTop,stWidth,stHeight);%mark
            else
              ious(t,ct)=boxdist(gtLeft,gtTop,gtWidth,gtHeight,stLeft,stTop,stWidth,stHeight);
            end
        end
    end
    
    
    fp(t)=numel(find(stInd(t,:)))-c(t);
    m(t)=g(t)-c(t);
    
    
end    

missed=sum(m);
falsepositives=sum(fp);
idswitches=sum(mme);
if options.eval3d
    MOTP=(1-sum(sum(d))/sum(c)/td) * 100; % avg distance to [0,100]
else
    %disp("check in evalIOU 7");
    if options.evalIOU 
      MOTP=sum(ious(ious>=td & ious<Inf))/sum(c) * 100; % avg ol
      sumDists = sum(ious(ious>=td & ious<Inf))
    else
      MOTP=sum(ious(ious<=td & ious>-Inf))/sum(c) * 100; % avg ol
      sumDists = sum(ious(ious<=td & ious>-Inf))
    end
end

MOTAL=(1-((sum(m)+sum(fp)+log10(sum(mme)+1))/sum(g)))*100;
MOTA=(1-((sum(m)+sum(fp)+(sum(mme)))/sum(g)))*100;
recall=sum(c)/sum(g)*100;
precision=sum(c)/(sum(fp)+sum(c))*100;
FAR=sum(fp)/Fgt;
 

%% MT PT ML
MTstatsa=zeros(1,Ngt);
for i=1:Ngt
    gtframes=find(gtInd(:,i));
    gtlength=length(gtframes);
    gttotallength=numel(find(gtInd(:,i)));
    trlengtha=numel(find(alltracked(gtframes,i)>0));
    if(gtlength/gttotallength >= 0.8 && trlengtha/gttotallength < 0.2)
        MTstatsa(i)=3;
    elseif(t>=find(gtInd(:,i),1,'last') && trlengtha/gttotallength <= 0.8)
        MTstatsa(i)=2;
    elseif trlengtha/gttotallength >= 0.8
        MTstatsa(i)=1;
    end
end
% MTstatsa
MT=numel(find(MTstatsa==1));PT=numel(find(MTstatsa==2));ML=numel(find(MTstatsa==3));

%% fragments
fr=zeros(1,Ngt);
for i=1:Ngt
    b=alltracked(find(alltracked(:,i),1,'first'):find(alltracked(:,i),1,'last'),i);
    b(~~b)=1;
    fr(i)=numel(find(diff(b)==-1));
end
FRA=sum(fr);

%Additional Info needed for aggregate scores over sequences
disp('from clearmot');
additionalInfoFileName = 'evaluation/additional_info_headers.txt';
additionalInfoHeader = [csv2cell(additionalInfoFileName, ',')]
%additionalInfo = struct("missed", sum(m), "FP", sum(fp),  "idswitches", sum(mme), "TP+FN", sum(g), "TP", sum(c), "Frames", Fgt, "gtTracks",Ngt, "MT", MT, "PT", PT, "ML", ML, "FRA", FRA, "sumDists", sumDists); 
% TODO: Iterate through list of header fields and conditionally(use if) assign the correct value
additionalInfoValues = [sum(m), sum(fp),  sum(mme), sum(g), sum(c), Fgt, Ngt, MT, PT, ML, FRA, sumDists]
additionalInfo = struct();
for i=1:columns(additionalInfoHeader)-3
    headerField = char(additionalInfoHeader(i))
    if (strcmp(headerField, 'missed'))
        additionalInfo.(headerField) = sum(m);
    elseif(strcmp(headerField, 'FP'))
        additionalInfo.(headerField) = sum(fp);
    elseif(strcmp(headerField, 'idswitches'))
        additionalInfo.(headerField) = sum(mme);
    elseif(strcmp(headerField, 'TP+FN'))
        additionalInfo.(headerField) = sum(g);
    elseif(strcmp(headerField, 'TP'))
        additionalInfo.(headerField) = sum(c);
    elseif(strcmp(headerField, 'Frames'))
        additionalInfo.(headerField) = Fgt;
    elseif(strcmp(headerField, 'gtTracks'))
        additionalInfo.(headerField) = Ngt; 
    elseif(strcmp(headerField, 'MT'))
        additionalInfo.(headerField) = MT; 
    elseif(strcmp(headerField, 'PT'))
        additionalInfo.(headerField) = PT;
    elseif(strcmp(headerField, 'ML'))
        additionalInfo.(headerField) = ML; 
    elseif(strcmp(headerField, 'FRA'))
        additionalInfo.(headerField) = FRA;
    elseif(strcmp(headerField, 'sumDists'))
        additionalInfo.(headerField) = sumDists; 
    end
end

additionalInfo
%disp(additionalInfo)
assert(Ngt==MT+PT+ML,'Hmm... Not all tracks classified correctly.');
metrics=[recall, precision, FAR, Ngt, MT, PT, ML, falsepositives, missed, idswitches, FRA, MOTA, MOTP, MOTAL];
end 

function ret=matched2d(gtInfo,stateInfo,t,map,mID,td, options)
    gtLeft=gtInfo.X(t,map)-gtInfo.W(t,map)/2;
    gtTop=gtInfo.Y(t,map)-gtInfo.H(t,map);
    gtWidth=gtInfo.W(t,map);    gtHeight=gtInfo.H(t,map);
    
    stLeft=stateInfo.Xi(t,mID)-stateInfo.W(t,mID)/2;
    stTop=stateInfo.Yi(t,mID)-stateInfo.H(t,mID);
    stWidth=stateInfo.W(t,mID);    stHeight=stateInfo.H(t,mID);
    
    %disp("check in evalIOU 8");
    if (options.evalIOU)
      ret = boxiou(gtLeft,gtTop,gtWidth,gtHeight,stLeft,stTop,stWidth,stHeight) >= td;
    elseif (options.evalDIOU)
      ret = boxdiou(gtLeft,gtTop,gtWidth,gtHeight,stLeft,stTop,stWidth,stHeight) <= td; %mark
    else
      ret = boxdist(gtLeft,gtTop,gtWidth,gtHeight,stLeft,stTop,stWidth,stHeight) <= td;
    end  
end


function ret=matched3d(gtInfo,stateInfo,t,map,mID,td)
    Xgt=gtInfo.Xgp(t,map); Ygt=gtInfo.Ygp(t,map);
    X=stateInfo.Xgp(t,mID); Y=stateInfo.Ygp(t,mID);
    ret=norm([Xgt Ygt]-[X Y])<=td;
    

end
