%% GMMCP Tracker
%% Simplified Version
%% 12/15/2014
%% Afshin Dehghan, Shayan Modiri Assari

clc;clear;close all;
warning off;
ones(1,10)'*ones(1,10);
addpath('./MOT_toolbox/');
addpath('./toolbox/');

%addpath('./MOT_toolbox/cplex/');
%addpath('/opt/ibm/ILOG/CPLEX_Studio128/cplex/matlab/x86-64_linux/');
%addpath('./MOT_toolbox/cplexWindows/')
addpath('./MOT_toolbox/GOG/');
addpath('./glpkmex-master/');

time_start = tic;

configFileName = 'config.txt';
[config] = textread(configFileName, "%s");

%% Sequence Info:
im_directory = config{1,1};
sequence_name = "DETRAC";
config_name = "default";
disp("sequence name: "), disp(sequence_name)
disp("im dir: "), disp(im_directory)
%threshold = config{3,1};

% It puts feature data in here
data_directory = './tmpData/';
%im_directory = fullfile(data_directory,sequence_name);
images = dir(fullfile(im_directory,'*.jpg'));
load('../DETRAC-detections.mat');
flag_visualization_ll_tracklet = false;
flag_visualize_midLevelTracklets = 0;

%% Initialize the parameters
[param_tracklet,param_merging,param_tracking,param_netCost]=set_param_gmmcp;
param_netCost.seqName = sequence_name;
param_tracklet.seqName = sequence_name;
param_tracking.seqName = sequence_name;
param_tracklet.data_directory = data_directory;
param_tracking.data_directory = data_directory;
param_tracklet.config_name = config_name;
param_tracklet.num_segment = round(length(images)/param_tracklet.num_frames);
fprintf('Found %d segments\n', param_tracklet.num_segment);

features_existed_prior_to_run = false;
%% Create Low-Level Tracklets and Extract Appearance Features
if(exist(fullfile(param_tracklet.data_directory,'Features',['tracklets_' config_name '_nf.mat']), 'file'))
    load(fullfile(param_tracklet.data_directory,'Features',['tracklets_' config_name '_nf.mat']));
    disp('Features already exist!');
    features_existed_prior_to_run = true;
else
    fprintf('Creating Low-level Tracklets  / ');
    tt = tic;
    segment = ll_tracklet_generator_nf(im_directory,detections, param_tracklet, images, flag_visualization_ll_tracklet);
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
    disp('iSegment')
    disp(iSegment)
    disp('param_tracklet.num_segment')
    disp(param_tracklet.num_segment)
    fprintf('computing tracklets for segment %d to %d \n',iSegment,min(iSegment+param_tracklet.num_cluster-1,param_tracklet.num_segment));
    [NN{cnt_batch},NN_original{cnt_batch}, nodes{cnt_batch}] = GMMCP_Tracklet_Generation(net_cost, iSegment,...
        min(iSegment+param_tracklet.num_cluster-1,param_tracklet.num_segment),[],sequence_name,0);
    cnt_batch = cnt_batch+1;
end

%% create NetCost Matrix for Merging
midLevelTracklets = extract_features_merging(NN, NN_original, nodes, segment, sequence_name,param_tracklet, flag_visualize_midLevelTracklets, im_directory);


%% Stitch the tracklets (Final Data Association)
fprintf('Stitching Tracklets to form final tracks \n ');
tt = tic;
[midLevelTracklets, finalTracks, trackRes] = stitchTracklets(midLevelTracklets);
fprintf('\nTime Elapsed:%0.2f\n',toc(tt));


%% Visualize Final Trackig Results
outDir = sprintf('trackingResults/%s/',sequence_name);
plotTracking(trackRes, im_directory, images, 1, outDir);

total_time = toc(time_start);
speed = length(images)/total_time;
if (~features_existed_prior_to_run)
    save -ascii speed.txt speed;
end

save completed.txt

disp('Goodbye...')