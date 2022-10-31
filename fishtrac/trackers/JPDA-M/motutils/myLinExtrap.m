function yi=myLinExtrap(Y,steps)
% 
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