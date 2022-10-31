function [S itl]= compute_itl_similarity_matrix(itl, method, eta_max)

N = size(itl,2);

% HEURISTIC: compute a max gap (this is good for speed)
l = [itl.length];
max_gap = mean(l(l>1))/2;


% HEURISTIC: max displacement rate
max_slope = 0;
for i=1:N
    dx = abs(itl(i).data(:,1:end-1) - itl(i).data(:,2:end));
    norm_dx = sum(dx.^2).^(1/2);
    max_slope = max([max_slope norm_dx]);
end

% DEBUG
%     fprintf('max gap: %.0f\n',max_gap);
%     fprintf('max dxy: %.0f\n',max_slope);



% add rank field to the itl structure
% we will use it
if ~isfield(itl,'rank')
    itl(1).rank = [];
end
S = -inf*ones(N,N);
for i=1:N
    for j=1:N
        if i==j
            s = -inf;
        else
%             [s ri rj rij]= similarity_itl_hstln(itl(i),itl(j),eta_max,'maxgap',max_gap,'maxslope',max_slope);            
            [s ri rj rij] = similarity_itl(itl(i),itl(j),eta_max,'method',method,'maxgap',max_gap,'maxslope',max_slope);
            itl(i).rank = ri;
            itl(j).rank = rj;
        end
        
        S(i,j) = s;
    end
end
