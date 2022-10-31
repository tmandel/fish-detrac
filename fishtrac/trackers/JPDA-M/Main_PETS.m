% Code for JPDA_m Tracker 
%
% Requires:
% Point detections 
% Linear dynamic model(s), e.g. constant velocity with small acceleration 
% Gurobi ILP solver
%
% The code is tested under Windows Seven (64bit)
%
% If you use this tracker for your research, please, cite:
% S. H. Rezatofighi, A. Milan, Z. Zhang, Q. Shi, A. Dick, I. Reid, "Joint 
% Probabilistic Data Association Revisited", IEEE International Conference 
% on Computer Vision (ICCV), 2015.

% Author: S. Hamid Rezatofighi
% Last updated: Nov 17, 2015

% For questions contact the author at: hamid.rezatofighi@adelaide.edu.au

pkg load statistics;
close all
clear all
clc

configFileName = 'config.txt';
[config] = textread(configFileName, "%s");
Detection_address="DETRAC-detections.mat"

%% Sequence Info:
Image_temp_addr = config{1,1};

%S_Name='S2'; % Sequence Name for PETS videos
%L_Name='L1'; % Camera name for PETS videos

AddPath; % Add the necessary paths 

% Image_address=[pwd,'\Data\PETS\PETS09\Images\',S_Name,filesep,L_Name];
%Image_temp_addr=fullfile(pwd,'Data','PETS','PETS09','Images',S_Name,filesep,L_Name);
% Address path to the image frames 
%Detection_address=fullfile(pwd,'Data','PETS','PETS09','Detections_and_GT',['PETS09-',S_Name,L_Name]);

% Detection_address=[pwd,'\Data\PETS\PETS09\Detections_and_GT\PETS09-',S_Name,L_Name]; % Address path to the detection and ground truth file

% Image info
file = dir(Image_temp_addr);
num_file = numel(file);

info = imfinfo([Image_temp_addr,filesep,file(3).name]);
u_image=info(1).Height;
v_image=info(1).Width;
cl_image=class(imread([Image_temp_addr,filesep,file(3).name]));
targetSize = v_image/30; %To get BBoxes, we need a rough estimate of taregt size: default is 1/30 image width
disp("Estimated target size");
disp(targetSize);


%% Parameters 

% Parameters for Heuristics
%The filtering now happens before this code is hit
param.Prun_Thre=-0.01; % Parameter for pruning detections with the confidence score less than this value  

param.tret=15; % Removing tracks with life time (# frames) less than this threshold
param.Term_Frame=45; % The parameter for termination condition

% Parameters for Kalman Filtering and JPDA
q1=0.5; % The standard deviation of the process noise for the dynamic model 
qm = 7; % The standard deviation of the measurement noise
param.Vmax=7; % maximum velocity that a target can has (used for initialization only) 

param.PD=0.89; % Detection Probabilty or the average of true positive rate for detections 
param.Beta=3/(u_image*v_image); % Beta is False detection (clutter) likelihhod=Pfa/(u_image*v_image)
% Beta=(PFa Average number of false detections per frame)/(Total volume)
param.Gate=(30)^0.5; % Gate size for gating
param.S_limit=100; % parameter to stop the gate size growing too much
param.N_H=100; % Number of m-best solutions for approximating JPDA distribution 
model.JPDA_multiscale=1; % Number of processing frames for multi-frame JPDA

% Parameters for visualization
param.Plott='No'; % Make it 'Yes' for any visualization 
param.Box_plot='Yes'; % Make it 'Yes' to show the bounding Box for each target
param.Font=12; % Font size fot the text

%% Tracking Model 
Tracking_Models

%% Initialization
% The distribution parameters for initial state p(x_0) 
model.X0=Initialization(Detection_address,param,model); % The initial mean
model.P0=blkdiag([qm 0;0 1],[qm 0;0 1]); % The initial covariance

%% JPDA_m Tracker
[XeT,PeT,Ff,Term_Con]=JPDA_m(Detection_address,model,param,"/blah/dummy/fake");

%% Post-processing (post processing and Removing tracks with small life spans)

X_size=cellfun(@(x) size(x,2), XeT, 'UniformOutput', false);
Ff=cellfun(@(x,y,z) x(1):x(1)+y-1-z, Ff,X_size,Term_Con, 'ErrorHandler', @errorfun, ...
    'UniformOutput', false);
Ff_size=cellfun(@(x) size(x,2), Ff, 'UniformOutput', false);
XeT=cellfun(@(x,y) x(:,1:y),XeT,Ff_size, 'ErrorHandler', @errorfun, ...
    'UniformOutput', false);
XeT2=XeT;
Ff2=Ff;
Ff(cellfun('size', XeT,2)<param.tret)=[];
XeT(cellfun('size', XeT,2)<param.tret)=[];


%% Bounding box estimation from detection
load(Detection_address) % load detection
Frame = num_file-2; % Total Number of frames
N_T=size(XeT,2);

%disp("GTINFO FIELDS:");
%disp(fieldnames(gtInfo));

stateInfo.X=zeros(Frame,N_T);
stateInfo.Y=zeros(Frame,N_T);
stateInfo.Xi=zeros(Frame,N_T);
stateInfo.Yi=zeros(Frame,N_T);

for n=1:N_T
    stateInfo.X(Ff{n},n)=XeT{n}(1,:);
    stateInfo.Xi(Ff{n},n)=stateInfo.X(Ff{n},n);
    stateInfo.Y(Ff{n},n)=XeT{n}(3,:);
    stateInfo.Yi(Ff{n},n)=stateInfo.Y(Ff{n},n);
end

stateInfo.frameNums=0:Frame-1;

%if strcmp(S_Name,'S2')&&strcmp(L_Name,'L2')
%    detections2=detections;
%    for it=1:size(detections,2)
%        detections2(it).xp=detections2(it).xi;
%        detections2(it).yp=detections2(it).yi;
%    end
%else
%    detections2=detections;
%end
detections2=detections;

stateInfo=getBBoxesFromState(stateInfo,targetSize,Ff,detections2);%,sceneInfo);


% Evaluation on cropped results using bounding box
stNew= stateInfo;
%gtNew=gtInfo;
save('stateInfo.mat','stNew');

%disp("GTNewFIELDS:");
%disp(fieldnames(gtNew));

%stNew.opt.track3d=0;

%stNew.X=stNew.Xi;stNew.X=stNew.Yi;
%gtNew.X=gtNew.Xi;gtNew.Y=gtNew.Yi;

%[metrics3d, metricsInfo3d, addInfo3d]=CLEAR_MOT(gtNew,stNew,struct('eval3d',0));
%printMetrics(metrics3d,metricsInfo3d,1);









