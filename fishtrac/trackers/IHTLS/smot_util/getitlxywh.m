function [idx,xys,rects] = getitlxywh(itl,t)

id = [itl.id];
t_start = [itl.t_start];
t_end   = [itl.t_end];
f = (t_start <= t) & (t <= t_end);
tidx = find(f==1);

rects = [];
xys = [];
idx = [];



if isfield(itl,'rect')

    for i=1:size(tidx,2)
        if itl(tidx(i)).omega(t-itl(tidx(i)).t_start+1 )
            
            rect = itl(tidx(i)).rect(:, t-itl(tidx(i)).t_start+1 );
            rects = [rects rect];
            idx = [idx id(tidx(i))];
        end
    end
    if ~isempty(rects)
        xys = rects(1:2,:) + rects(3:4,:)/2;
    end

else
    for i=1:size(tidx,2)
        if itl(tidx(i)).omega(t-itl(tidx(i)).t_start+1 )
            
            xy = itl(tidx(i)).data(:, t-itl(tidx(i)).t_start+1 );
            xys = [xys xy];
            idx = [idx id(tidx(i))];
        end
    end
end