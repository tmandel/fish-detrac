function [stateInfo, speed] = run_tracker(curSequence, baselinedetections)

%% setting parameters for tracking
c_en      = 10;     %% 10 birth cost, has no influence on the result
c_ex      = 10;     %% 10 death cost, has no influence on the result
c_ij      = -2;     %% 0 transition cost
betta     = 0.01;   %% 0.2 betta, increase will have less tracks, for every single detection
max_it    = inf;    %% inf max number of iterations (max number of tracks)
thr_cost  = 18;     %% 18 max acceptable cost for a track (increase it to have more tracks.), for every tracklet 19.8

time_start = tic;
%% Run object/human detector on all frames.
frameNums = curSequence.frameNums;
dres = greedy_detect_generator(baselinedetections, frameNums);

%% Running tracking algorithms
dres_dp_nms   = tracking_dp(dres, c_en, c_ex, c_ij, betta, thr_cost, max_it, 1);
dres_dp_nms.r = -dres_dp_nms.id;
totalTime = toc(time_start);
speed = numel(frameNums)/totalTime;          

%% save the tracking result
fnum = numel(frameNums);
bboxes_tracked = dres2bboxes(dres_dp_nms, fnum);  %% we are visualizing the "DP with NMS in the lop" results. Can be changed to show the results of DP or push relabel algorithm.
stateInfo = saveStateInfo(bboxes_tracked);