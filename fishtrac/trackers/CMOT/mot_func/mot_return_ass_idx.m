function [all_idx] = mot_return_ass_idx(child_idx,prt_idx,root_idx,c_fr)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

all_idx = zeros(1,c_fr);
all_idx(end) = root_idx;
all_idx(end-1) = prt_idx;
nofc = length(child_idx);
all_idx(end-nofc:end-2) = child_idx(2:end);


end