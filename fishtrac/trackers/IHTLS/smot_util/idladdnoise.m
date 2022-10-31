function [idl, fp_idl, fn_idl]= idladdnoise(idl,noise)

% noise is a structure with three fields = { fn, fp, gn}
% noise.fn : false negatives
% noise.fp : false positives
% noise.gn : gaussian noise

T = size(idl,2);
N = zeros(1,T); % number of detections per frame

% idl sructures to keep log of modifications
aidl = struct('rect',[],'xy',[]);   % added points
fp_idl = repmat(aidl,[1 T]);
fn_idl = fp_idl;   % removed points

% Analyze the video for statistics
XY = [];
WH = [];
for t=1:T
    N(t) = size(idl(t).xy,1);
    if N(t) > 0 
        XY = [XY; idl(t).xy];
        WH = [WH; idl(t).rect(:,3:4)];
    end
end
XYmin = min(XY,[],1);
XYmax = max(XY,[],1);
WHmean = mean(WH);
WHstd  = std(WH);
sumN = sum(N);
Nfn = floor(sumN*noise.fn);
Nfp = floor(sumN*noise.fp);


% false negatives 
for n=1:Nfn
    % pick a frame
    t = randi(T,1);
    % pick a detections
    if N(t)>0
        k = randi(N(t),1);    
        % log it
        fn_idl(t).xy = [fn_idl(t).xy;idl(t).xy(k,:)];  
        fn_idl(t).rect = [fn_idl(t).rect;idl(t).rect(k,:)];
        % remove it
        idl(t).xy(k,:) = [];
        idl(t).rect(k,:) = [];        
        N(t) = N(t) - 1;
    end
end


% false positives
for n=1:Nfp
    % pick a frame
    t = randi(T,1);
    % add a detection
    xy = rand(1,2).*(XYmax-XYmin) + XYmin;
    wh = randn(1,2).*WHstd + WHmean;
    rect = [xy-wh/2 wh];
    
    % log it
    fp_idl(t).xy = [fp_idl(t).xy;xy];  
    fp_idl(t).rect = [fp_idl(t).rect;rect];
    
    % add it to the data
    idl(t).xy = [idl(t).xy; xy];
    idl(t).rect = [idl(t).rect; rect];    
    N(t) = N(t) + 1;
end

% inline noise
if noise.gn > 0
    for t=1:T        
        
    end
end
