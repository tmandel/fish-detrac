function [C_x,C_y]=LeftToCenter(x,y,height,width)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.


h_height = height/2;
h_width  = width/2;

C_x = x + round(h_width);
C_y = y+ round(h_height);







end