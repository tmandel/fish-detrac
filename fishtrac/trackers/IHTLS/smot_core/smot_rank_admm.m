function R = smot_rank_admm(x,eta,varargin)

[D,N] = size(x);

nr = ceil(N/(D+1))*D;
nc = N - ceil(N/(D+1))+1;

defMaxRank = min([nr nc]);
defMinRank = 1;
defOmega   = ones(1,N);
defLambda  = 0.1;

% Check user input parameters
p = inputParser;

addParamValue(p,'maxrank',defMaxRank,@isnumeric);
addParamValue(p,'minrank',defMinRank,@isnumeric);
addParamValue(p,'omega',defOmega,(@(x) (isnumeric(x)|islogical(x))));
addParamValue(p,'lambda',defLambda,@isnumeric);
parse(p,varargin{:});


R_max = p.Results.maxrank;
R_max = min([nr nc R_max]);
R_min = p.Results.minrank;
omega = p.Results.omega;
lambda = p.Results.lambda;


% if omega has a 0 needs inpainting
if sum(omega==0)>0
    % do inpainting
    % mustafa's code requires scaling to (0-1)
%     maxx = max(x(:));
%     tx = x/maxx;
%     tx_hat = l2_fastalm_mo(tx,lambda,'omega',omega);    
%     x  = tx_hat*maxx;
      x = l2_fastalm_mo(x,lambda,'omega',omega);    
%     [x ~] = cvx_min_hankel_rank_con(x,eta,omega);
    35;
end


H = hankel_mo(x,[0 R_max]);

s = svd(H);
R = sum(s>eta);

% I am not sure if necessary
% if R<R_min || R>R_max
%     warning('rank out of range!');
% end
R = max(R_min,R);
R = min(R_max,R);

