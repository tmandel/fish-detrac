function [stateInfo, speed] = run_tracker(curSequence, baselinedetections)
% Bayesian Multi-Object Tracking Using Motion Context from Multiple Objects (WACV2015)
% Last updated date: 2015. 04. 08
% Copyright (C) 2015 Ju Hong Yoon, jh.yoon82@gmail.com
% All rights reserved.

% Parameters
opt.display = false;
opt.print = false;
opt.s_size = [0, 0, 10000]; % height size for MOT
opt.d_ratio  = [1,1]; % detection ratio (for width/height)
opt.cost_threshold = 2.5;
opt.cost_threshold2 = 2.5;
opt.PASCAL_Th = 0.1; % 0.2
opt.Height_Th = 0.8;
opt.App_Th = 0.2; % 0.2
opt.Hist_Th = 0.8;
opt.max_gap = 30;
opt.margin_u = 50;
opt.margin_v = 10000;
opt.learn = 0.9;
opt.app_off = 0;
opt.img_margin_u = 50;

%% multi-object tracking
imgFolder = curSequence.imgFolder;
imgFolder = strcat('../../', imgFolder);
dataset = curSequence.dataset;

% Sequence size        
frame = imread([imgFolder dataset(1).name]);
[hs, ws, dims] = size(frame);
opt.imgsz = [hs,ws,dims]; % height size, width size, dimension
opt.init_frames = 4;
% Modeling
% filter parameters for motion and detection
filter_parameters();         

% Data seqeunce
observation = parseDetection(baselinedetections, curSequence.frameNums);
Match_Init = {};
Match_Init_Hist = {};
Track = {};
param.MAX_LAB = 0;
RMN = [];
dcStartTime = tic;
for fidx = 1:length(curSequence.frameNums)    
    f = curSequence.frameNums(fidx);
    % frame index
    frame = imread([imgFolder dataset(fidx).name]);
    if(curSequence.frameNums(1) <= 1)
        finput = fidx;
    else
        finput = f;
    end
    % Detection Conversion
    [Detect, Detection_App] = detection_conversion(observation, finput, opt, frame);
    % Tracking by Data Association
    new_set = Detect'; % (detection dimension by number of detections)
    new_set_hist = Detection_App;
    % Initialization of Event
    for i=1:length(Track)
        Track{i}.Assignment = {};
        Track{i}.AssignmentCost = {};
        Track{i}.Penalty = {};
        Track{i}.EventCost = [];
    end        
    % Current Track Label
    if(~isempty(Track))
        Current_Label = zeros(1,length(Track));
        for i=1:length(Track)
            Lab = Track{i}.lab;
            Current_Label(i) = Lab;
        end
    end
    % Initialization for Track Association
    for i=1:length(Track)
        Track{i}.detection = {};
        Track{i}.asso_spatial = {};
    end
   %% Hierachical Search
    associated_idx = [];
    used_track_idx = [];
    det_asso_idx = [];        
    [Cost2ndMat] = Cost_RMN(Track, RMN, new_set, new_set_hist, opt, param);
    if(~isempty(Track) && ~isempty(new_set))
        [Assignment2, AssignCost] = munkres(Cost2ndMat);
        for i=1:length(Track)
            idx_m = find(Assignment2(i,:)==1);
            if(Cost2ndMat(i,idx_m) < opt.cost_threshold2-eps)
                Track{i}.detection = [new_set(1:2,idx_m)+new_set(3:4,idx_m)/2;new_set(3:4,idx_m)]; % associated (Track Label;Detection Label)
                Track{i}.HSV = new_set_hist{idx_m};
                Track{i}.asso_spatial = 0.5;
                det_asso_idx = [det_asso_idx, idx_m]; % collecting associated detections
                associated_idx = [associated_idx, idx_m]; % Associated detection label
                used_track_idx = unique([used_track_idx, i]);
            end
        end
    end
    % Smoothing
    if(~isempty(Track))
        [Track] = track_update_rmn(Track, frame, opt, param, f);
        [Track] = track_smooth(Track);
    end        
    % Track save
    if(~isempty(Track))
        for i=1:length(Track)
            if(Track{i}.survival == 0)
                Lab = Track{i}.lab;
                Track_Save{Lab} = [Track{i}.states(1:4,:);Track{i}.frame];
            end
        end
    end
    if(fidx==length(curSequence.frameNums))
        for i=1:length(Track)
            Lab = Track{i}.lab;
            Track_Save{Lab} = [Track{i}.states(1:4,:);Track{i}.frame];
        end
    end
    % Removing Associated detection
    if(~isempty(det_asso_idx))
        new_set(:,det_asso_idx) = []; % remove assoicated detections
        Idx = 0;
        new_set_hist_temp = new_set_hist;
        new_set_hist = {};
        for i=1:size(new_set_hist_temp,2)
            if(sum(det_asso_idx==i)==0)
                Idx = Idx + 1;
                new_set_hist{Idx} = new_set_hist_temp{i};
            end
        end
    end     
    % Track Management
    [Track] = track_management(Track);        
    % Matching for Initialization
    [InitObj, InitObj_Hist, Match_Init, Match_Init_Hist] = match_initialization(new_set, new_set_hist, Match_Init, Match_Init_Hist, f, opt);
    % Object Initialization
    NewT = []; % New Track Index
    [Track, NewT, param] = object_initialization(InitObj, InitObj_Hist, Track, NewT, param);
    % RMN Update/Constructing RMN Observation
    if(~isempty(RMN) && ~isempty(Track))
        [RMN] = rmn_observation(Track, RMN);
    end        
    % Relative Motion Network Update
    if(isempty(RMN) && ~isempty(Track) && ~isempty(NewT))
        if(length(Track)>1)
            [RMN, Track] = rmn_initialization(Track, param, f);
        end
    elseif(~isempty(RMN) && ~isempty(Track))
        % RMN Update
        [RMN, Track] = rmn_update(Track, RMN, NewT, opt, param, f);
        if(~isempty(NewT)) % if NewTs exist
            [RMN, Track] = adding_new_rmn(Track, NewT, RMN, opt, param, f);
        end
    end        
    % Track Link
    for i=1:length(Track)
        Track{i}.link = unique(Track{i}.link);
    end                
    % Prediction Based on RMN
    if(~isempty(Track))
        [Track] = prediction_rmn(Track, RMN, param);
    end 
end
%% Save tracking results for evaluation
speed = length(curSequence.frameNums)/toc(dcStartTime);
num_frame = length(curSequence.frameNums);
if(exist('Track_Save','var'))
    num_obj = size(Track_Save,2);
else
    num_obj = 1;
end
stateInfo = [];
stateInfo.F = curSequence.frameNums(end);
stateInfo.X = zeros(num_frame,num_obj); 
stateInfo.Y = zeros(num_frame,num_obj);
stateInfo.targetsExist = zeros(num_obj,2);
stateInfo.tiToInd = zeros(num_frame,num_obj);
stateInfo.stateVec = [];
stateInfo.frameNums = curSequence.frameNums;
stateInfo.Xgp = zeros(num_frame,num_obj);
stateInfo.Ygp = zeros(num_frame,num_obj);
stateInfo.Xi = zeros(num_frame,num_obj);
stateInfo.Yi = zeros(num_frame,num_obj);
stateInfo.H = zeros(num_frame,num_obj);
stateInfo.W = zeros(num_frame,num_obj);

if(exist('Track_Save','var'))
    stateInfo.N = size(Track_Save,2);
    idx = 1;
    for i = 1:size(Track_Save,2)
        Obj = Track_Save{i};
        for o=1:size(Obj,2)
            State = Obj(:,o);
            if(curSequence.frameNums(1)==0)
                frame = State(5) + 1;
            else
                frame = State(5);
                frame = frame - curSequence.frameNums(1) + 1;
            end
            State = State(1:4);

            % i: Label
            % frame: frame index
            stateInfo.tiToInd(frame,i) =  idx;
            stateInfo.stateVec = [stateInfo.stateVec;State(1)];
            stateInfo.X(frame,i) = State(1);
            stateInfo.Y(frame,i) = State(2)+State(4)/2;
            stateInfo.Xgp(frame,i) =  State(1); % X position
            stateInfo.Ygp(frame,i) =  State(2); % Y position
            stateInfo.Xi(frame,i) =  State(1);
            stateInfo.Yi(frame,i) =  State(2)+State(4)/2;
            stateInfo.H(frame,i) =  State(4); % Width
            stateInfo.W(frame,i) =  State(3); % Height
            idx = idx + 2;
        end
    end
end
