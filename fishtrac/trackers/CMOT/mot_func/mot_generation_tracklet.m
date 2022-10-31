function [Trk,param,Obs_grap] = mot_generation_tracklet(rgbimg,Trk,Obs_grap,detections,param,Y_set,fr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

ct = 0; non_iso =[];
new_thr = param.new_thr;
for i=1:length(Y_set(fr).child)
    prt_idx = Y_set(fr).child{i};
    if length(prt_idx) <= 1
        [child_idx] = mot_search_association(Y_set, fr,prt_idx);
        [ass_idx] = mot_return_ass_idx(child_idx,prt_idx,i,fr);
    else
        child_idx =[]; tmp_ass_idx =[]; ass_ln=[];
        for j=1:length(prt_idx)
            [child_idx{j}] = mot_search_association(Y_set, fr, prt_idx(j));
            [tmp_ass_idx{j}] = mot_return_ass_idx(child_idx{j},prt_idx(j),i,fr);
            ass_ln(j) = length(find(tmp_ass_idx{j} ~= 0));
        end
        [~,pid] = max(ass_ln);
        ass_idx= tmp_ass_idx{pid};
        
    end
    
    if  length(find(ass_idx ~=0)) >= new_thr
        ct = ct + 1;
         [Trk,param] = mot_tracklets_components_setup(rgbimg,Trk,detections,fr,ass_idx,param,[]);
        idx = [];
        nT = length(find(ass_idx ~= 0));
        for h=1:nT
             idx1 = find(Obs_grap(fr+h-nT).iso_idx == 1);
             idx2 = idx1(ass_idx(end+h-nT));
             idx = [idx, idx2];
        end
        non_iso(ct,:) = idx;
    end
end



for j=1:size(non_iso,2)
    setr =  unique(non_iso(:,j));
     if Obs_grap(fr+j-nT).iso_idx(setr) ==0
         puase;
     end
    Obs_grap(fr+j-nT).iso_idx(setr) = 0;
end
  
end