function [Affinity] = mot_shape_similarity(rh, rw, th,tw) 
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

Affinity = exp(-1.5*((abs(rh - th)/(rh + th)) + (abs(rw - tw)/(rw + tw))));
