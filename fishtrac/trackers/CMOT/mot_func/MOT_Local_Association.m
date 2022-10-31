
function [Trk, Obs_grap, Obs_info] = MOT_Local_Association(Trk, detections, Obs_grap, param, ILDA, fr, rgbimg)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.


Z_meas = detections(fr);
ystate = [Z_meas.x, Z_meas.y, Z_meas.w, Z_meas.h]';
Obs_grap(fr).iso_idx = ones(size(detections(fr).x));
Obs_info.ystate = [];
Obs_info.yhist  =[];
if ~isempty(ystate)
    yhist = mot_appearance_model_generation(rgbimg, param, ystate);
    Obs_info.ystate = ystate;
    Obs_info.yhist = yhist;
    
    tidx = Idx2Types(Trk,'High');
    yidx = find(Obs_grap(fr).iso_idx == 1);
    
    
    if ~isempty(tidx) && ~isempty(yidx)
        Trk_high =[]; Z_set =[];
        
        trk_label = [];
        conf_set = [];
        % For tracklet with high confidence
        for ii=1:length(tidx)
            i = tidx(ii);
            Trk_high(ii).hist = Trk(i).A_Model;
            Trk_high(ii).FMotion = Trk(i).FMotion;
            Trk_high(ii).last_update = Trk(i).last_update;
            
            Trk_high(ii).h = Trk(i).state{end}(4);
            Trk_high(ii).w = Trk(i).state{end}(3);
            Trk_high(ii).type = Trk(i).type;
            trk_label(ii) = Trk(i).label;
            conf_set = [conf_set,  Trk(i).Conf_prob];
        end
        
        % For detections
        meas_label = [];
        for jj=1:length(yidx)
            j = yidx(jj);
            Z_set(jj).hist = yhist(:,:,j);
            Z_set(jj).pos = [ystate(1,j);ystate(2,j)];
            Z_set(jj).h =  ystate(4,j);
            Z_set(jj).w = ystate(3,j);
            meas_label(jj) = j;
        end
        
        thr = param.obs_thr;
        
        
        
        [score_mat] = mot_eval_association_matrix(Trk_high, Z_set, param, 'Obs', ILDA);
        [matching, ~] = mot_association_hungarian(score_mat, thr);
        
        
        if ~isempty(matching)
            for i=1:size(matching,1)
                ass_idx_row = matching(i,1);
                ta_idx = tidx(ass_idx_row);
                ass_idx_col = matching(i,2);
                ya_idx = yidx(ass_idx_col);
                Trk(ta_idx).hyp.score(fr) = score_mat(matching(i,1),matching(i,2));
                Trk(ta_idx).hyp.ystate{fr} =  ystate(:,ya_idx);
                Trk(ta_idx).hyp.new_tmpl = yhist(:,:,ya_idx);
                Trk(ta_idx).last_update = fr;
                Obs_grap(fr).iso_idx(ya_idx) = 0;
                
            end
        end
    end
end
end