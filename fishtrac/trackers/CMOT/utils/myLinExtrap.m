function yi=myLinExtrap(Y,steps)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

% only takes two element vectors Y
if length(Y)~=2, error('Y must be of length 2'); end


n=Y(1); m=diff(Y);

if steps<0
    xi=steps:-1;
else
    xi=(1:steps)+1;
end

yi = m*xi + n;


end