function [stateInfo, speed] = run_tracker(curSequence, baselinedetections)
%% Robust Online Multi-Object Tracking based on Tracklet Confidence 
%% and Online Discriminative Appearance Learning (CVPR2014)

DrawOption.isdraw = 0;
DrawOption.iswrite = 0;
DrawOption.isprint = 1;
   
% set parameters
disp('setting parameters');
mot_setting_params();
% load detections
disp('parsing detections');
detections = parseDetections(baselinedetections, curSequence.frameNums);
frame_start = 1;
frame_end = length(detections);

All_Eval = [];cct = 0;Trk = []; Trk_sets = [];
%% Initiailization Tracklet
disp('Initiailization Tracklet');
tstart1 = tic;
init_frame = frame_start + param.show_scan;
init_img_set = cell(1, init_frame);
for i=1:init_frame
    Obs_grap(i).iso_idx = ones(size(detections(i).x));
    Obs_grap(i).child = []; 
    Obs_grap(i).iso_child =[];
end
Obs_grap = mot_pre_association(detections, Obs_grap, frame_start, init_frame);
st_fr = 1;
en_fr = init_frame;

for fr = 1:init_frame
    filename = strcat(curSequence.imgFolder, curSequence.dataset(fr).name);
    init_img_set{fr} = imread(strcat('../../',strrep(filename,'//','/')));
end

disp('Calling MOT');
[Trk, param, Obs_grap] = MOT_Initialization_Tracklets(init_img_set,Trk,detections,param,Obs_grap,init_frame);

disp('Tracking');
%% Tracking 
for fr = init_frame+1:frame_end
    filename = strcat(curSequence.imgFolder, curSequence.dataset(fr).name);
    init_img_set{fr} = imread(strcat('../../',strrep(filename,'//','/')));
    %% Local Association
	%disp('Local Association');
    [Trk, Obs_grap, Obs_info] = MOT_Local_Association(Trk, detections, Obs_grap, param, ILDA, fr, init_img_set{fr});
    %% Global Association
	%disp('Global Association');
    [Trk, Obs_grap] = MOT_Global_Association(Trk, Obs_grap, Obs_info, param, ILDA, fr);
    %% Tracklet Confidence Update
	%disp('Tracklet Confidence Update');
    Trk = MOT_Confidence_Update(Trk,param,fr, param.lambda);
    Trk = MOT_Type_Update(init_img_set{fr},Trk,param.type_thr,fr);
    %% Tracklet State Update & Tracklet Model Update
	%disp('State Update');
    Trk = MOT_State_Update(Trk, param, fr);
    %% New Tracklet Generation 
	%disp('Generation');
    [Trk, param, Obs_grap] = MOT_Generation_Tracklets(init_img_set,Trk,detections,param,Obs_grap,fr);
    %% Incremental subspace learning
    if param.use_ILDA
		%disp('ILDA');
        rgbimg = init_img_set{fr};
        ILDA = MOT_Online_Appearance_Learning(rgbimg, imgFolder, dataset, fr, Trk, param, ILDA);
    end
    %% Tracking Results
	%disp('Results');
    Trk_sets = MOT_Tracking_Results(Trk,Trk_sets,fr);
end
TotalTime = toc(tstart1);
speed = frame_end/TotalTime;

%% Draw Tracking Results
disp('Drawing');
DrawOption.new_thr = param.new_thr;
% Box colors indicate the confidences of tracked objects
% High (Red)-> Low (Blue)

stateInfo = MOT_Draw_Tracking(Trk_sets, curSequence.imgFolder, curSequence.dataset, frame_end, DrawOption); 