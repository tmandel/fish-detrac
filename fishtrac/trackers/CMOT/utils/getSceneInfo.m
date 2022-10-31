function sceneInfo=getSceneInfo(scenario)
% fill all necessary information about the
% scene into the sceneInfo struct
%
% Required:
%   detfile         detections file (.idl or .xml)
%   frameNums       frame numbers (eg. frameNums=1:107)
%   imgFolder       image folder
%   imgFileFormat   format for images (eg. frame_%04d.jpg)
%   targetSize      approx. size of targets (default: 5 on image, 350 in 3d)
%
% Required for 3D Tracking only
%   trackingArea    tracking area
%   camFile         camera calibration file (.xml PETS format)
%
% Optional:
%   gtFile          file with ground truth bounding boxes (.xml CVML)
%   initSolFile     initial solution (.xml or .mat)
%   targetAR        aspect ratio of targets on image
%   bgMask          mask to bleach out the background
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.


global opt
% opt=getOptions;
% general folders
homefolder=getHomeFolder;
dbfolder=fullfile(filesep,'storage','databases'); if ispc, dbfolder=fullfile('D:','storage','databases'); end
if exist('/gris','dir'), dbfolder=fullfile(filesep,'gris','takatuka_dbases'); end

% detection file
switch(scenario)
    case {23,25,27,70,71,72,73,74,75,80}
        dataset='PETS2009';
    case {40,41,42}
        dataset='TUD';
    case {30,31,32,35,36,37}
        dataset='TUD10';
    case {50,51,52,53}
        dataset='ETH-Person';
    case {60,61,62}
        dataset='AVSS';
    case {48}
        dataset='UBC';
    case {90,91,92}
        dataset='DA-ELS';
    otherwise
        error('unknown scenario');
end

% sequence name
switch(scenario)
    case 23
        seqname='PETS2009-S2L1-c1';
    case 25
        seqname='PETS2009-S2L2-c1';
    case 27
        seqname='PETS2009-S2L3-c1';
    case 31
        seqname='TUD10-ped1-c1';
    case 32
        seqname='TUD10-ped1-c2';
    case 36
        seqname='TUD10-ped1-c1';
    case 37
        seqname='TUD10-ped2-c2';
    case 40
        seqname='TUD-Campus';
    case 41
        seqname='TUD-Crossing';
    case 42
        seqname='TUD-Stadtmitte';
    case 48
        seqname='Hockey';
    case {50,51,52,53}
        seqname=sprintf('seq%02d',scenario-50);
    case 60
        seqname='AB_Easy';
    case 61
        seqname='AB_Medium';
    case 62
        seqname='AB_Hard';
    case 70
        seqname='PETS2009-S1L1-1-c1';
    case 71
        seqname='PETS2009-S1L1-2-c1';
    case 72
        seqname='PETS2009-S1L2-1-c1';
    case 73
        seqname='PETS2009-S1L2-2-c1';
    case 74
        seqname='PETS2009-S1L3-1-c1';
    case 75
        seqname='PETS2009-S1L3-2-c1';
    case 80
        seqname='PETS2009-S3MF1-c1';
    case {90,91,92,93,94}
        seqname=sprintf('s%02d',scenario-90);
    otherwise
        
        error('unknown scenario');
end

% frameNums
switch(scenario)
    case 20 % terrace1
        sceneInfo.frameNums=1:2000;
    case 21 % terrace2
        sceneInfo.frameNums=1:2000;
    case {22,23} % PETS 2009 S2 L1
        sceneInfo.frameNums=0:794;
    case 24 % PETSMONO occlusion
        sceneInfo.frameNums=0:794;
    case 25
        sceneInfo.frameNums=0:435;
    case 27
        sceneInfo.frameNums=0:239;
    case {30,31,32,33} % TUD10 ped
        sceneInfo.frameNums=1:1400;
        %         sceneInfo.frameNums=1:300;
    case {35,36,37} % TUD10 ped2
        sceneInfo.frameNums=1:1999;
        %         sceneInfo.frameNums=1:199;
        %         sceneInfo.frameNums=1670:1680;
        %         sceneInfo.frameNums=760:770;
    case 40 % tud-campus
        sceneInfo.frameNums=90:160;
    case {41,44} % tud-crossing
        sceneInfo.frameNums=1:201;
    case 42 % tud-stadtmitte
        sceneInfo.frameNums=7022:7200;
        %         sceneInfo.frameNums=7022:7100;
    case 45 % eth central xing1
        sceneInfo.frameNums=1600:2200;
    case 46 % eth central xing1
        sceneInfo.frameNums=3300:3600;
    case 47 % eth central xing1
        sceneInfo.frameNums=7433:7811;
    case 48 % UBC Hockey
        sceneInfo.frameNums=700:800;
    case 50 % ETH Person seq0
        sceneInfo.frameNums=180:678;
    case 51 % ETH Person seq1
        sceneInfo.frameNums=0:999;
    case 52 % ETH Person seq2
        sceneInfo.frameNums=0:450;
    case 53 % ETH Person seq3
        sceneInfo.frameNums=100:453;
    case {60,61,62} % AVSS
        sceneInfo.frameNums=1:2000;
    case 70
        sceneInfo.frameNums=0:220;
    case 71
        sceneInfo.frameNums=0:240;
    case 72
        sceneInfo.frameNums=0:200;
    case 73
        sceneInfo.frameNums=0:130;
    case 74
        sceneInfo.frameNums=0:90;
    case 75
        sceneInfo.frameNums=0:343;
    case 80
        sceneInfo.frameNums=1:107;
    case 81
        sceneInfo.frameNums=0:231;
    case 82
        sceneInfo.frameNums=0:108;
    case 83
        sceneInfo.frameNums=0:169;
    case 84
        sceneInfo.frameNums=0:92;
    case 85
        sceneInfo.frameNums=0:107;
    case 86
        sceneInfo.frameNums=0:184;
        %     case 90
        %         sceneInfo.frameNums=1:593;
        %     case 91
        %         sceneInfo.frameNums=1:307;
        %     case 92
        %         sceneInfo.frameNums=1:420;
    case {101,131} % EnterExitCrossingPaths1 cor, front
        sceneInfo.frameNums=0:382;
    case {102,132} % EnterExitCrossingPaths2 cor, front
        sceneInfo.frameNums=0:484;
    case {103,133} % OneLeaveShop1 cor, front
        sceneInfo.frameNums=0:294;
    case {104,134} % OneLeaveShop2 cor, front
        sceneInfo.frameNums=0:1118;
    case {105,135} % OneLeaveShopReenter1 cor, front
        sceneInfo.frameNums=0:389;
    case {106,136} % OneLeaveShopReenter2 cor, front
        sceneInfo.frameNums=0:559;
    case {107,137} % OneShopOneWait1 cor, front
        sceneInfo.frameNums=0:1376;
    case {108,138} % OneShopOneWait2 cor, front
        sceneInfo.frameNums=0:1461;
    case {109,139} % OneStopEnter1 cor, front
        sceneInfo.frameNums=0:1499;
    case {110,140} % OneStopEnter2 cor, front
        sceneInfo.frameNums=0:2724;
    case {111,141} % OneStopMoveEnter1 cor, front
        sceneInfo.frameNums=0:1586;
    case {112,142} % OneStopMoveEnter2 cor, front
        sceneInfo.frameNums=0:2236;
    case {113,143} % OneStopMoveNoEnter1 cor, front
        sceneInfo.frameNums=0:1664;
    case {114,144} % OneStopMoveNoEnter2 cor, front
        sceneInfo.frameNums=0:1034;
    case {115,145} % OneStopNoEnter1 cor, front
        sceneInfo.frameNums=0:1664;
    case {116,146} % OneStopNoEnter2 cor, front
        sceneInfo.frameNums=0:1034;
    case {117,147} % ShopAssistant1 cor, front
        sceneInfo.frameNums=0:1674;
    case {118,148} % ShopAssistant2 cor, front
        sceneInfo.frameNums=0:3699;
    case {119,149} % ThreePastShop1 cor, front
        sceneInfo.frameNums=0:1649;
    case {120,150} % ThreePastShop2 cor, front
        sceneInfo.frameNums=0:1520;
    case {121,151} % TwoEnterShop1 cor, front
        sceneInfo.frameNums=0:1644;
    case {122,152} % TwoEnterShop2 cor, front
        sceneInfo.frameNums=0:1604;
    case {123,153} % TwoEnterShop3 cor, front
        sceneInfo.frameNums=0:1604;
    case {124,154} % TwoLeaveShop1 cor, front
        sceneInfo.frameNums=0:1342;
    case {125,155} % TwoLeaveShop2 cor, front
        sceneInfo.frameNums=0:599;
    case {126,156} % WalkByShop1 cor, front
        sceneInfo.frameNums=0:2359;
    case 160
        sceneInfo.frameNums=171:184;
    case {161,162}
        sceneInfo.frameNums=97:114;
    otherwise
        warning('unknown scenario getFrameNums');
end


detfolder=fullfile(homefolder,'diss','detections','hog-hof-linsvm',dataset,seqname);
% detfolder=fullfile(homefolder,'diss','detections','swd-v2',dataset,seqname);
% detfolder=fullfile(dbfolder,'data-tud','det','',dataset,seqname);

% detfile
switch(scenario)
    case 51
        sceneInfo.detfile=fullfile(detfolder,'test-result-nms-0.8.idl');
    case 53
        sceneInfo.detfile=fullfile(dbfolder,dataset,seqname,'seq03-annot.idl');
    case 62
        sceneInfo.detfile=fullfile(detfolder,['AVSS-' seqname sprintf('-result-00000-05059-nms.idl',length(sceneInfo.frameNums)-1)]);
    case 48
        sceneInfo.detfile=fullfile(dbfolder,dataset,seqname,'detections.mat');
    case {90,91,92}
        sceneInfo.detfile=fullfile(detfolder,'detections.mat');
    case {23,25,27,70,71,72,73,80,40,41,42}
        sceneInfo.detfile=fullfile(dbfolder,'data-tud','det',dataset,[seqname '-det.xml']);
    otherwise
        sceneInfo.detfile=fullfile(detfolder,[seqname sprintf('-result-00000-%05d-nms.idl',length(sceneInfo.frameNums)-1)]);
        
end
assert(exist(sceneInfo.detfile,'file')==2,'detection file does not exist')


% img Folder
switch(scenario)
    case 23
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S2','L1','Time_12-34','View_001',filesep);
    case 25
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S2','L2','Time_14-55','View_001',filesep);
    case 27
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S2','L3','Time_14-41','View_001',filesep);
    case 31
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'ped1','c1',filesep);
    case 32
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'ped1','c2',filesep);
    case 36
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'ped2','c1',filesep);
    case 37
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'ped2','c2',filesep);
    case 40
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'tud-campus-sequence',filesep);
    case 41
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'tud-crossing-sequence',filesep);
    case 42
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'tud-stadtmitte',filesep);
    case 48
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,seqname,filesep);
    case {50,51,52,53}
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,seqname,'left',filesep);
    case {60,61,62}
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,seqname,filesep);
    case 70
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S1','L1','Time_13-57','View_001',filesep);
    case 71
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S1','L1','Time_13-59','View_001',filesep);
    case 72
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S1','L2','Time_14-06','View_001',filesep);
    case 73
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S1','L2','Time_14-31','View_001',filesep);
    case 80
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,'Crowd_PETS09','S3','Multiple_Flow','Time_12-43','View_001',filesep); % 80
    case {90,91,92,93}
        sceneInfo.imgFolder=fullfile(dbfolder,dataset,seqname,filesep);
    otherwise
        error('unknown scenario image Folder');
end
assert(exist(sceneInfo.imgFolder,'dir')==7,'imgfolder does not exist')

% image extension
imgExt='.jpg';
switch(scenario)
    case {20,21,40,41,42,44,50,51,52,53}
        imgExt='.png';
end
sceneInfo.imgFileFormat='frame_%04d';

switch(scenario)
    case 40
        sceneInfo.imgFileFormat='DaSide0811-seq6-%03d';
    case 41
        sceneInfo.imgFileFormat='DaSide0811-seq7-%03d';
    case 42
        sceneInfo.imgFileFormat='DaMultiview-seq%04d';
    case 48
        sceneInfo.imgFileFormat='h%04d';
    case {50,51,52,53}
        sceneInfo.imgFileFormat='image_%08d_0';
    case {90,91,92,93}
        sceneInfo.imgFileFormat='%05d';
end

% append file extension
sceneInfo.imgFileFormat=[sceneInfo.imgFileFormat imgExt];

% if no frame nums, determine from images
if ~isfield(sceneInfo,'frameNums')
    imglisting=dir([sceneInfo.imgFolder '*' imgExt]);
    sceneInfo.frameNums=1:length(imglisting);
end

% image dimensions
[sceneInfo.imgHeight, sceneInfo.imgWidth, ~]= ...
    size(imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,sceneInfo.frameNums(1))]));




%% tracking area
% if we are tracking on the ground plane
% we need to explicitly secify the tracking area
% otherwise image = tracking area
if opt.track3d
    switch(scenario)
        case {23,25,27,70,71,72,73,80}
            sceneInfo.trackingArea=[-14069.6, 4981.3, -14274.0, 1733.5];
        case {30,31,32}
            sceneInfo.trackingArea=[-197    6708   -2021    6870];
        case {35,36,37}
            sceneInfo.trackingArea=[-3438    5271   -2018    7376];
        case 40
            sceneInfo.trackingArea=[-0150 0506   28   1081];
        case 41
            sceneInfo.trackingArea=[-19, 12939, -48, 10053];
        case 42
            sceneInfo.trackingArea=[-19, 12939, -48, 10053];
        otherwise
            error('Definition of tracking area needed for 3d tracking');
    end
    
else
    sceneInfo.trackingArea=[1 sceneInfo.imgWidth 1 sceneInfo.imgHeight];   % tracking area
end

%% camera
cameraconffile=[];
if opt.track3d
    cam=1;
    switch(scenario)
        case {20,21} %terrace
            cameraconffile=sprintf('%sepfl/terrace-tsai-c%i.xml',dbfolder,cam);
        case {22, 23,25,27,70,71,72,73,74,75,80,81,82,83,84,85,86} %PETS2009
            cameraconffile=fullfile(dbfolder,dataset,'View_001.xml');
        case 24
            cameraconffile=sprintf('%sPETS2009/View_001.xml',dbfolder);
        case 30
            cameraconffile=sprintf('%sTUD10/ped1/c%i-calib.xml',dbfolder,cam);
        case 31
            cameraconffile=fullfile(dbfolder,dataset,'ped1/c1-calib.xml');
        case 32
            cameraconffile=fullfile(dbfolder,dataset,'ped1/c2-calib.xml');
        case 36
            cameraconffile=fullfile(dbfolder,dataset,'ped2/c1-calib.xml');
        case 37
            cameraconffile=fullfile(dbfolder,dataset,'ped2/c2-calib.xml');
        case {40,43}
            cameraconffile=fullfile(dbfolder,dataset,'tud-campus-calib.xml');
        case {41,44}
            cameraconffile=fullfile(dbfolder,dataset,'tud-crossing-calib.xml');
        case 42
            cameraconffile=fullfile(dbfolder,dataset,'tud-stadtmitte-calib.xml');
        case {45,46,47}
            cameraconffile=sprintf('%sETH-Central/pedxing-seq1-calib.xml',dbfolder);
        case {60,61,62}
            cameraconffile=sprintf('%sAVSS/AB_calib.xml',dbfolder);
        case intersect(scenario,101:126);
            cameraconffile=sprintf('%sCAVIAR/CAVIAR-cor.xml',dbfolder);
        case intersect(scenario,131:156);
            cameraconffile=sprintf('%sCAVIAR/CAVIAR-front.xml',dbfolder);
        case intersect(scenario,160:163) %%% !!! FIX !!!
            cameraconffile=sprintf('%sCAVIAR/CAVIAR-front.xml',dbfolder);
        otherwise
            error('unknown scenario');
    end
end
sceneInfo.camFile=cameraconffile;

if ~isempty(sceneInfo.camFile)
    sceneInfo.camPar=parseCameraParameters(sceneInfo.camFile);
end


%% target size
sceneInfo.targetSize=20;                % target 'radius'
sceneInfo.targetSize=sceneInfo.imgWidth/30;
if opt.track3d, sceneInfo.targetSize=350; end

%% target aspect ratio
sceneInfo.targetAR=1/3;
switch(scenario)
    case 48 % Hockey
        sceneInfo.targetAR=1/2;
    case {90,91,92} % aerial
        sceneInfo.targetAR=1;
end


%% ground truth
sceneInfo.gtFile='';
switch(scenario)
    case {23,25,27,70,71,72,73,80}
        sceneInfo.gtFile=fullfile(dbfolder,'data-tud','gt',dataset,[seqname '.mat']);
    case 31
        sceneInfo.gtFile=fullfile(dbfolder,dataset,'ped1','c1','GT2d_full_new.mat');
    case 32
        sceneInfo.gtFile=fullfile(dbfolder,dataset,'ped1','c2','GT2d_full_new.mat');
    case {40,41}
        sceneInfo.gtFile=fullfile(dbfolder,'data-tud','gt',dataset,[seqname '-interp.mat']);
    case 42
        sceneInfo.gtFile=fullfile(dbfolder,'data-tud','gt',dataset,[seqname '.mat']);
        %         sceneInfo.gtFile='/home/aanton/diss/others/yangbo/TUD/TUD_Stadtmitte.avi.gt.mat';        % Yang
    case 62
        sceneInfo.gtFile=fullfile(dbfolder,'data-tud','gt',dataset,'AB_Hard','GT2d_new.mat');
    otherwise
        warning('ground truth?');
end


global gtInfo
sceneInfo.gtAvailable=0;
if ~isempty(sceneInfo.gtFile)
    sceneInfo.gtAvailable=1;
    % first determine the type
    [pathtogt, gtfile, fileext]=fileparts(sceneInfo.gtFile);
    
    if strcmpi(fileext,'.xml') % CVML
        gtInfo=parseGT(sceneInfo.gtFile);
    elseif strcmpi(fileext,'.mat')
        % check for the var gtInfo
        fileInfo=who('-file',sceneInfo.gtFile);
        varExists=0; cnt=0;
        while ~varExists && cnt<length(fileInfo)
            cnt=cnt+1;
            varExists=strcmp(fileInfo(cnt),'gtInfo');
        end
        
        if varExists
            load(sceneInfo.gtFile,'gtInfo');
        else
            warning('specified file does not contained correct ground truth');
            sceneInfo.gtAvailable=0;
        end
    end
    
    if opt.track3d
        if ~isfield(gtInfo,'Xgp') || ~isfield(gtInfo,'Ygp')
            [gtInfo.Xgp gtInfo.Ygp]=projectToGroundPlane(gtInfo.X, gtInfo.Y, sceneInfo);
        end
    end
    
    %     if strcmpi(fileext,'.xml'),     save(fullfile(pathtogt,[gtfile '.mat']),'gtInfo'); end
end

%% check
if opt.track3d
    if ~isfield(sceneInfo,'trackingArea')
        error('tracking area [minx maxx miny maxy] required for 3d tracking');
    elseif ~isfield(sceneInfo,'camFile')
        error('camera parameters required for 3d tracking. Provide camera calibration or siwtch to 2d tracking');
    end
end

%% camera viewing angle
% even if we have camera and ground truth
% try estimating perspective
% sceneInfo.htobj=estimateTargetsSize(sceneInfo);

%% background mask
switch(scenario)
    case {23,25,27,70,71,72,73,80,81,82,83,84,85,42}
        sceneInfo.bgMask=fullfile(dbfolder,dataset,'bgmask.mat');
end


end