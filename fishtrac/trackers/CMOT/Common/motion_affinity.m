function prob_pdf = motion_affinity(x,mean,var)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

prob_pdf = exp(-0.5*(x-mean)'*inv(var)*(x-mean));
