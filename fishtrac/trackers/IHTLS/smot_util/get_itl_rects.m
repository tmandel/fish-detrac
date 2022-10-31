function [idx,rects] = get_itl_rects(itl,t)

id = [itl.id];
t_start = [itl.t_start];
t_end   = [itl.t_end];
f = (t_start <= t) & (t <= t_end);
tidx = find(f==1);

rects = [];
idx = [];

for i=1:size(tidx,2)
    if itl(tidx(i)).omega(t-itl(tidx(i)).t_start+1 )
        rect = itl(tidx(i)).rect(:, t-itl(tidx(i)).t_start+1 );
        rects = [rects rect];
        idx = [idx id(tidx(i))];
    end
end