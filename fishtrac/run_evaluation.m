% clear, clc, close all;
warning off all;
global options tracker

%% add the path of functions
addpath(genpath('utils'));
addpath(genpath('evaluation'));
addpath(genpath('display'));
tracker.trackerName = 'GOG';
%% initialize the parameters for evalution
options = initialize_environment();
% select the type of detector, i.e., DPM, ACF, R-CNN and CompACT. Multiple detectors are welcomed.


%% evaluate the tracker
detectionEvaluation();