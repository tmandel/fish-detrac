function [decision]= mot_is_reg(pos,left,right)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

Lx = left(1);
Ly = left(2);
Rx = right(1);
Ry = right(2);

if (pos(1)>Lx(1) && pos(1)<Rx)...
        && (pos(2)>Ly && pos(2)<Ry)
    decision = 1; 
else
    decision = 0; 
end




