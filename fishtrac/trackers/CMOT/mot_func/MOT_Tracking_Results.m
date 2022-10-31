function [Trk_sets] = MOT_Tracking_Results(Trk,Trk_sets,fr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

[hg_indx] = Idx2Types(Trk,'High');
[low_indx] = Idx2Types(Trk,'Low');

del_indx =[];
for i=1:length(low_indx)
    efr = Trk(low_indx(i)).efr;
    if abs(efr - fr) > 5    
       del_indx = [del_indx,i];
    end
end

Trk_sets(fr).high = hg_indx;
Trk_sets(fr).low = setdiff(low_indx, low_indx(del_indx)); 

for i=1:length(Trk)
    Trk_sets(fr).states{i} = cell2mat(Trk(i).state);
    Trk_sets(fr).conf(i) = Trk(i).Conf_prob;
    Trk_sets(fr).label(i) = Trk(i).label;
end
