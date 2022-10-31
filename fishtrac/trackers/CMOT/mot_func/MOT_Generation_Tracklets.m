function [Trk ,param, Obs_grap] = MOT_Generation_Tracklets(init_img_set,Trk,detections,param,...
    Obs_grap,cfr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

st_fr = cfr-param.show_scan; en_fr = cfr;
ISO.meas= []; ISO.node = [];
[ISO] = mot_non_associated(detections, Obs_grap, ISO,st_fr,en_fr);
[ISO] = mot_pre_association_tracking(ISO,st_fr,en_fr);
[Trk,param,Obs_grap] = mot_generation_tracklet(init_img_set,Trk,Obs_grap,...
    ISO.meas,param, ISO.node,cfr);


    