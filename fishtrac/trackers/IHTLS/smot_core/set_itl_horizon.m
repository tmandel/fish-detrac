function itl_dst = set_itl_horizon(itl_dst,itl_src,horizon)

Nh = size(itl_src,2);

hormin = horizon(1);
hormax = horizon(2);

% WARNING: I am remerging the tracklets (inefficient coding)
idklog = [];
for n=1:Nh
    K = length(itl_src(n).id);
    if K>1
        id1 = itl_src(n).id(1);
        for k = 2:K
            idk = itl_src(n).id(k);
            itl_dst(id1) = mergeitl(itl_dst(id1),itl_dst(idk));
            idklog = [idklog idk];            
        end        
    end
end

itl_dst(idklog) = [];
