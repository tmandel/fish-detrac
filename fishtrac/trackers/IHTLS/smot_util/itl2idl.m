function idl = itl2idl(itl)

% idl(t) is composed of 2 fields for now
% rect 4xN N many detections
% xy 2xN centroids

if isempty(itl)
    idl = [];
    return;
end

T_end = max([itl.t_end]);

for t = 1:T_end
    [idx,rects] = get_itl_rects(itl,t);
    if ~isempty(rects)
        xy = rects(1:2,:) + rects(3:4,:)/2;
    else
        xy = [];
    end
    idl(t).rect = rects';
    idl(t).xy = xy';
    
end