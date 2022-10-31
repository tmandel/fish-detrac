%% GMMCP Tracker
%% Simplified Version
%% 12/15/2014
%% Afshin Dehghan, Shayan Modiri Assari

clc;clear;close all;
warning off;
ones(1,10)'*ones(1,10);
addpath('./MOT_toolbox/');
addpath('./toolbox/')

addpath('./MOT_toolbox/cplex/');
addpath('./MOT_toolbox/cplexWindows/')


%% Sequence Info
sequence_name = 'AVG-TownCentre';
data_directory = '/home/afshin/Documents/Data/MOT/2DMOT2015/test/';
im_directory = fullfile(data_directory,sequence_name,'img1');
images = dir(fullfile(im_directory,'*.jpg'));
load(fullfile(data_directory,sequence_name,'det/det.mat'));
flag_visualization_ll_tracklet = true;
flag_visualize_midLevelTracklets = 1;

%% Initialize the parameters
[param_tracklet,param_merging,param_tracking,param_netCost]=set_param_gmmcp;
param_netCost.seqName = sequence_name;
param_tracklet.seqName = sequence_name;
param_tracking.seqName = sequence_name;
param_tracklet.data_directory = data_directory;
param_tracking.data_directory = data_directory;
param_tracklet.num_segment = round(length(images)/param_tracklet.num_frames);

%% Create Low-Level Tracklets and Extract Appearance Features
if(exist(fullfile(param_tracklet.data_directory,'Features',['tracklets_' param_tracklet.seqName '.mat']), 'file'))
    load(fullfile(param_tracklet.data_directory,'Features',['tracklets_' param_tracklet.seqName '.mat']));
else
    fprintf('Creating Low-level Tracklets  / ');
    tt = tic;
    segment = ll_tracklet_generator(im_directory,detections,param_tracklet, images, flag_visualization_ll_tracklet);
    fprintf('\nTime Elapsed:%0.2f\n',toc(tt));
end

if (strcmp(sequence_name, 'PL2'))
    segment(1:2)=[];
end
param_tracklet.num_segment = length(segment);

%% Create NetCost Matrix
fprintf('Creating NetCost Matrix for Low-level Tracklets  / ');
tt = tic;
net_cost = create_netCost(segment,param_netCost);
fprintf('\nTime Elapsed:%0.2f\n',toc(tt));

%% Run GMMCP with ADN on non-overlaping segments
cnt_batch=1;
for iSegment=1:round(param_tracklet.num_cluster/2):param_tracklet.num_segment
    fprintf('computing tracklets for segment %d to %d \n',iSegment,min(iSegment+param_tracklet.num_cluster-1,param_tracklet.num_segment));
    [NN{cnt_batch},NN_original{cnt_batch}, nodes{cnt_batch}] = GMMCP_Tracklet_Generation(net_cost, iSegment,...
        min(iSegment+param_tracklet.num_cluster-1,param_tracklet.num_segment),[],sequence_name,0);
    cnt_batch = cnt_batch+1;
end

%% create NetCost Matrix for Merging
midLevelTracklets = extract_features_merging(NN, NN_original, nodes, segment, sequence_name,param_tracklet, flag_visualize_midLevelTracklets);


%% Stitch the tracklets (Final Data Association)
fprintf('Stitching Tracklets to form final tracks \n ');
tt = tic;
[midLevelTracklets, finalTracks, trackRes] = stitchTracklets(midLevelTracklets);
fprintf('\nTime Elapsed:%0.2f\n',toc(tt));


%% Visualize Final Trackig Results
outDir = sprintf('./trackingResults/%s/',sequence_name);
plotTracking(trackRes, im_directory, images, 0, outDir);
