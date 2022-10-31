function [L_x L_y] = CenterToLeft(x,y,height,width)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

% (x,y): Center position

h_height = height./2;
h_width  = width./2;

L_x = x - round(h_width);
L_y = y- round(h_height);







end