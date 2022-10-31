function itl = associate_itl(itl,param,horizon)

N = size(itl,2);

if nargin == 3
    hormin = horizon(1);
    hormax = horizon(2);
else
    hormin = -inf;
    hormax = +inf;
end


% Get the active tracklets in the horizon
itlh = get_itl_horizon(itl,horizon);

% eliminate very small itls
len = [itlh.length];
itlh(len<=2) = [];

if ~isempty(itlh)
    % Do merging in the horizon
    dN = 1;
    
    while dN > 0
        if param.debug
            figure(11)
            drawitl(itlh)
        end
        
        
        % Compute similarities
        [S,itlh] = compute_itl_similarity_matrix(itlh,param.similarity_method,param.eta_max);
        
        
        % Compute associations
        % 1) Use minus similarity, because lapjv solves minimization problem.
        assign = generalizedLinearAssignment(-S,-param.min_s);

        
        % Do associations
        itlh = process_itl_associations(itlh,assign,param);
        
        Nnew = size(itlh,2);
        dN = N - Nnew;
        N = Nnew;
        
        if param.debug
            figure(11)
            drawitl(itlh)
        end
        
    end
    
    % merge with real tracklets
    itl = set_itl_horizon(itl,itlh,horizon);
    

end








% 
% function A = compute_itl_associations(S,minS)
% 
% % 1) Use minus similarity, because lapjv solves minimization problem.
% A = generalizedLinearAssignment(-S,-minS);
% 
% % N = size(S,2);
% 
% % 1) Use minus similarity, because lapjv solves minimization problem.
% % 2) Use slack variables to relax sum(X)==1, so if there are very low
% % similarities they will be omitted. Only confident associations will be
% % processed
% 
% % S = [S  ones(N,N)*minS ];
% % S = [S; ones(N,2*N)*minS ];
% % [A,C] = lapjv(-S);
% % A = A(1:N);
% % A(A>N) = 0;
% % 35;
% 
% 





