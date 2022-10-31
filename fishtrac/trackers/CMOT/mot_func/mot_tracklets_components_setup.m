function [Trk, param] = mot_tracklets_components_setup(img,Trk,detections,cfr,y_idx,param,tmp_label)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

noft = length(Trk)+1;
ass_idx = y_idx;
nofa = length(find(y_idx ~= 0));

Trk(noft).Conf_prob = param.init_prob;

Trk(noft).type = 'High';
Trk(noft).reliable = 'False';
Trk(noft).isnew = 1;
Trk(noft).sub_img = [];
Trk(noft).status = 'none';

if ~isempty(tmp_label)
    Trk(noft).label = tmp_label;
else
    [param,idx] = Labelling(param);
    Trk(noft).label = idx;
end

Trk(noft).ifr = cfr -nofa + 1;
Trk(noft).efr = 0;
Trk(noft).last_update = cfr;

Acc_tmpl = zeros(param.Bin*3, param.subregion);
for i=1:nofa
    tmp_idx = cfr-i+1;
    Trk(noft).state{tmp_idx}(1,1) = detections(tmp_idx).x(ass_idx(tmp_idx)); 
    Trk(noft).state{tmp_idx}(2,1) = detections(tmp_idx).y(ass_idx(tmp_idx)); 
    Trk(noft).state{tmp_idx}(3,1) = detections(tmp_idx).w(ass_idx(tmp_idx)); 
    Trk(noft).state{tmp_idx}(4,1) = detections(tmp_idx).h(ass_idx(tmp_idx)); 
    
    tmpl = mot_appearance_model_generation(img{tmp_idx},param,Trk(noft).state{tmp_idx});

    Acc_tmpl = Acc_tmpl + tmpl;
end


% Appearnce Model
Trk(noft).A_Model = Acc_tmpl./nofa;


% Forward Motion Model
[XX,PP] = mot_motion_model_generation(Trk(noft),param,'Forward');

lt = size(XX,2);
Trk(noft).FMotion.X(:,cfr-lt+1 :cfr) = XX;
Trk(noft).FMotion.P(:,:,cfr-lt+1 :cfr) = PP;


Trk(noft).BMotion.X = [];
Trk(noft).BMotion.P = [];

Trk(noft).hyp.score(cfr) = 0;
Trk(noft).hyp.ystate{cfr} = [];



end