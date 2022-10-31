
function [Trk, Obs_grap] = MOT_Global_Association(Trk, Obs_grap, Obs_info, param, ILDA, fr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

Refer =[]; Test= [];
all_indx = 1:length(Trk);
[low_indx] = Idx2Types(Trk,'Low');
[high_indx] = setdiff(all_indx, low_indx);
yidx = find(Obs_grap(fr).iso_idx == 1);

yhist = Obs_info.yhist;
ystate = Obs_info.ystate;

High_trk =[]; Low_trk=[]; Y_set = [];
if ~isempty(low_indx)
    % For tracklets with low confidence
    for ii=1:length(low_indx)
        i = low_indx(ii);
        Low_trk(ii).hist = Trk(i).A_Model;
        Low_trk(ii).FMotion = Trk(i).FMotion;
        
        Low_trk(ii).h = Trk(i).state{end}(4);
        Low_trk(ii).w = Trk(i).state{end}(3);
        Low_trk(ii).last_update = Trk(i).last_update;
        Low_trk(ii).end_time = Trk(i).efr;
        Low_trk(ii).type = Trk(i).type;
    end
    
    % For tracklet with high confidence
    for jj=1:length(high_indx)
        j = high_indx(jj);
        High_trk(jj).hist = Trk(j).A_Model;
        High_trk(jj).h = Trk(j).state{end}(4);
        High_trk(jj).w = Trk(j).state{end}(3);
        High_trk(jj).FMotion = Trk(j).FMotion;
        [XX,PP] = mot_motion_model_generation(Trk(j),param,'Backward');
        
        High_trk(jj).BMotion.X = XX;
        High_trk(jj).BMotion.P = PP;
        
        High_trk(jj).last_update = Trk(j).last_update;
        High_trk(jj).init_time = Trk(j).ifr;
    end
    
    iso_label = [];
    if ~isempty(yidx)

        % For detections        
        for jj=1:length(yidx)
            j = yidx(jj);
            Y_set(jj).hist = yhist(:,:,j);
            Y_set(jj).pos = [ystate(1,j);ystate(2,j)];
            Y_set(jj).h =  ystate(4,j);
            Y_set(jj).w = ystate(3,j);
            iso_label = j;
        end
    end
    
    thr = param.obs_thr;
    
    [score_trk] = mot_eval_association_matrix(Low_trk,High_trk,param,'Trk',ILDA);
    [score_obs] = mot_eval_association_matrix(Low_trk, Y_set, param,'Obs', ILDA);
    score_mat = [score_trk, score_obs];
    [matching, Affinity] = mot_association_hungarian(score_mat, thr);

    
    alpha = param.alpha;
    
    rm_idx = [];
    for m=1: length(Affinity)
        mat_idx = matching(m,2);
        
        % Tracklet Association
        if mat_idx <= length(high_indx)
            t_idx = low_indx(matching(m,1));
            y_idx = high_indx(matching(m,2));
            
            Trk(y_idx).ifr = Trk(t_idx).ifr;
            fr1 = Trk(t_idx).ifr;
            fr2 = Trk(t_idx).efr;
            for kk=fr1:fr2
                Trk(y_idx).state{kk} = Trk(t_idx).state{kk};
            end
            
            numHyp =  length(Trk(t_idx).hyp.score);
            for kk=fr1:numHyp
                Trk(y_idx).hyp.score(kk) = Trk(t_idx).hyp.score(kk);
                Trk(y_idx).hyp.ystate{kk} = Trk(t_idx).hyp.ystate{kk};
            end
            
            for kk=numHyp + 1:fr-1
                Trk(y_idx).hyp.score(kk) = param.init_prob;
                Trk(y_idx).hyp.ystate{kk}  = [];
            end
            Trk(y_idx).A_Model = alpha*(Trk(t_idx).A_Model)+(1-alpha)*(Trk(y_idx).A_Model);
            
            % Motion Model Generation
            XX = [];
            numState = length(Trk(y_idx).state);
            XX(1,:) = Trk(y_idx).state{fr1}(1);             
            XX(3,:) = Trk(y_idx).state{fr1}(2);
            XX(2,:) = 0; XX(4,:) = 0;
            PP = param.P;
            for ff=fr1:numState
                tState = Trk(y_idx).state{ff};
                if ~isempty(tState)
                    [XX,PP] = km_estimation(XX,tState(1:2),param,PP);
                else
                    tState = Trk(y_idx).state{fr2};
                    [XX,PP] = km_estimation(XX,[],param,PP);
                    Trk(y_idx).state{ff}(1:2,:) = [XX(1);XX(3)];
                    Trk(y_idx).state{ff}(3:4,:) = [tState(1);tState(3)];
                end
                Trk(y_idx).FMotion.X(:,ff) = XX;
                Trk(y_idx).FMotion.P(:,:,ff) = PP;
            end
           
            Trk(y_idx).label = Trk(t_idx).label;
            Trk(y_idx).type = 'High';
            rm_idx = [rm_idx, t_idx];
            
        else % Observation Association
            m_idx = matching(m,2) - length(high_indx);
            t_idx = low_indx(matching(m,1));
            y_idx = yidx(m_idx); 
            Trk(t_idx).hyp.score(fr) = Affinity(m);
            Trk(t_idx).hyp.ystate{fr} =  ystate(:,y_idx);
            Trk(t_idx).hyp.new_tmpl = yhist(:,:,y_idx);
            Trk(t_idx).last_update = fr;
            Obs_grap(fr).iso_idx(y_idx) = 0;
        end

    end
    
    if ~isempty(rm_idx)
        Trk(rm_idx) = [];
    end
end

end