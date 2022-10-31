function [param,idx] = Labelling(param)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

label = param.label;
idx = min(find(label==0));
param.label(idx) = 1;
