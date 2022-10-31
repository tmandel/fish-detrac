function [tracks,trackFrame] = run_GOG(detOrig,minFrame,maxFrame,param)

addpath('3rd_party/voc-release3.1/');           %% this code is downloaded from http://people.cs.uchicago.edu/~pff/latent/
addpath('3rd_party/cs2/');                      %% this code is downloaded from http://www.igsystems.com/cs2/index.html and then mex'ed to run faster in matlab.

dres = bboxes2dres(detOrig,minFrame,maxFrame);
if ~isempty(dres.x)
    dres = build_graph(dres,param.overlap_threshold);
    
    %%% setting parameters for tracking
    c_en      = 10;     %% birth cost
    c_ex      = 10;     %% death cost
    c_ij      = 0;      %% transition cost
    betta     = -1;    %% betta
    max_it    = inf;    %% max number of iterations (max number of tracks)
    thr_cost  = 15;     %% max acceptable cost for a track (increase it to have more tracks.)
    
    %%% Running tracking algorithms
    display('in DP tracking ...')
    
    tic
    display('in DP tracking with nms in the loop...')
    dres_dp_nms = tracking_dp(dres, c_en, c_ex, c_ij, betta, thr_cost, max_it, 1);
    dres_dp_nms.r = -dres_dp_nms.id;
    toc
    
    
    ids_unique = unique(dres_dp_nms.id)';
    tracks = cell(1,length(ids_unique));
    cnt = 1;
    for iID = ids_unique
        indID = find(dres_dp_nms.id == iID);
        tracks{1,cnt}=[dres_dp_nms.fr(indID), dres_dp_nms.id(indID), dres_dp_nms.x(indID), ...
            dres_dp_nms.y(indID), dres_dp_nms.x(indID)+dres_dp_nms.w(indID), ...
            dres_dp_nms.y(indID)+dres_dp_nms.h(indID),dres_dp_nms.origInd(indID)];
        tracks{1,cnt} = flipud(tracks{1,cnt});
        cnt = cnt+1;
    end
    
    minFrame = min(dres_dp_nms.fr);
    maxFrame = max(dres_dp_nms.fr);
    trackFrame = cell(1,maxFrame-minFrame+1);
    cnt = 1;
    for iFrame = minFrame:maxFrame
        indFr = find(dres_dp_nms.fr==iFrame);
        trackFrame{cnt}= [dres_dp_nms.fr(indFr), dres_dp_nms.id(indFr), dres_dp_nms.x(indFr), ...
            dres_dp_nms.y(indFr), dres_dp_nms.x(indFr)+dres_dp_nms.w(indFr), ...
            dres_dp_nms.y(indFr)+dres_dp_nms.h(indFr)];
        cnt = cnt+1;
    end
else
    tracks=[];
    trackFrame = [];
end