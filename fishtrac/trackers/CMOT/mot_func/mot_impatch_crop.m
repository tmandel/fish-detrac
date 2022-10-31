function [bbs] = mot_impatch_crop(cn_est)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

nofs = size(cn_est,1);
for i=1:nofs
    pos = cn_est(i,1:2);
    scale = cn_est(i,3:4);
    bbs{i} = [pos,scale];
end


end

