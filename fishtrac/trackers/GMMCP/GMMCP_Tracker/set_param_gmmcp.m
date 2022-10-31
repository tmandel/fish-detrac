%% Set the parameters for tracking 
%% GMMCP Tracker
%% Afshin Dehghan, Shayan Modiri Assari

function [param_tracklet,param_merging,param_tracking,param_netCost]=set_param_gmmcp()

% Parameters for tracklet generation 
param_merging.num_cluster = 4;
param_merging.max_error = 250;
param_merging.sigma = 30;
param_merging.smooth = 1;
param_merging.show = 0;

% Parameters for tracklet generation 
param_tracklet.num_frames = 10;
param_tracklet.reject_tracklets = round(param_tracklet.num_frames/1.5);
param_tracklet.detection_threshold = -0.7;
param_tracklet.threshold_merging = 0.3;
param_tracklet.overlap_threshold = 0.3;
param_tracklet.num_cluster = 4;


% parameter for netCost matrix generation first layer
param_netCost.max_error = 150;
param_netCost.sigma = 20;     
param_netCost.smooth = 1;
param_netCost.show = 0;

% Tracking
param_tracking.motionWeight = 0.3;
param_tracking.appearanceWeight = 0.7;
