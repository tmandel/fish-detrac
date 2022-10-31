function [likelihood] = mot_color_similarity(refer_hist,target_hist,var)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.


if nargin >2
    [N,M] = size(target_hist);
    bhattcoeff = sum(sqrt(refer_hist.*target_hist)); 
    Dist = sqrt(ones(1,M) - bhattcoeff);
    likelihood =  exp(sum((-1/var)*Dist.^2));
else
    [likelihood]= color_similarity_only_bhat(refer_hist,target_hist);
end



end

function [likelihood]=color_similarity_only_bhat(refer_hist,target_hist)


method =1;
bhattcoeff = sum(sqrt(refer_hist.*target_hist)); 
if bhattcoeff >1
    [r p] = corrcoef(refer_hist,target_hist);
    likelihood = p(1,2);
else
    likelihood = mean(bhattcoeff);
end
end
