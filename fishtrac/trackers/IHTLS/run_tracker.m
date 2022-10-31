function [stateInfo, speed] = run_tracker(curSequence, baselinedetections)

% set random generator
%rng('default');

%% set parameters
param.similarity_method = 'ihtls';
param.min_s = 1e-2;     % minimum similarity for tracklets
param.mota_th = 0.5;    % we want the detections to stay in width/2.
param.debug = false;
param.hor = 30;
param.eta_max = 2;
        
%% multi-object tracking
% load detection
idlDetections = txt2idl(baselinedetections, curSequence.frameNums);
% run tracking             
[itlf, etime] = smot_associate(idlDetections, param);
speed = numel(curSequence.frameNums)/etime; 
% save output for noiseless case
stateInfo = saveResults(itlf, idlDetections, curSequence);