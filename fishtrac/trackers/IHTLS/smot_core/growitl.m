function itl = growitl(itl,max_D)

N_itl = size(itl,2);

done = false;
l = [];
% TODO: write this loop better
while ~done
    
    % find length 1 itls
%     idx1 = find(itl.length==1);
    
    35;
    
    
    
    
    
    
    for i=1:N_itl
    for j=1:N_itl
        gap = (itl(j).t_start - itl(i).t_end) - 1;
        if gap == 0
            if itl(i).length == 1 && itl(j).length > 1
                % grow to past
                xy_j = itl(j).data(:,2:-1:1);
                xy_i = itl(i).data;
                % order 1 comprasion
                xy_i_hat = 2*xy_j(:,2) - xy_j(:,1);
                d = sum((xy_i - xy_i_hat).^2);
                if d < max_D
                    itl(j) = mergeitl(itl(i),itl(j));
                    itl(i).t_start = -inf;
                    itl(i).t_end = -inf;                    
                    l = [l i];  % add to delete list
%                     N_itl = N_itl-1;
%                     done = false;
                end
            elseif itl(i).length > 1 && itl(j).length == 1
                % grow to future
                xy_j = itl(j).data;
                xy_i = itl(i).data(:,end-1:end);
                % order 1 comprasion
                xy_j_hat = 2*xy_i(:,2) - xy_i(:,1);
                d = sum((xy_j - xy_j_hat).^2);
                if d < max_D
                    itl(i) = mergeitl(itl(i),itl(j));
                    itl(j).t_start = -inf;
                    itl(j).t_end = -inf;
                    l = [l j];  % add to delete list
%                     N_itl = N_itl-1;
%                     done = false;
                end
            else
                % if they are both length 1 
                % do nothing
            end            
        end
    end
    end
    
    if isempty(l)
        done = true;    
    else
        itl(l) = [];
        l = [];
        N_itl = size(itl,2);        
    end
    
%     dN_itl = N_itl - size(itl,2);
%     N_itl = size(itl_2);
end