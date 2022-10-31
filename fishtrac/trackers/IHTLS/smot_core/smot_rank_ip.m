function R = smot_rank_ip(x,eta,varargin)

[D,N] = size(x);

nr = ceil(N/(D+1))*D;
nc = N - ceil(N/(D+1))+1;

defMaxRank = min([nr nc]);
defMinRank = 1;
defOmega   = ones(1,N);

% Check user input parameters
p = inputParser;

addParamValue(p,'maxrank',defMaxRank,@isnumeric);
addParamValue(p,'minrank',defMinRank,@isnumeric);
addParamValue(p,'omega',defOmega,(@(x) (isnumeric(x)|islogical(x))));
parse(p,varargin{:});


R_max = p.Results.maxrank;
R_max = min([nr nc R_max]);
R_min = p.Results.minrank;
omega = p.Results.omega;


% if omega has a 0 needs inpainting
if sum(omega==0)>0
    % do inpainting
    [x ~] = cvx_min_hankel_rank_con(x,eta,omega);
    35;
end


H = hankel_mo(x,[0 R_max]);

s = svd(H);
R = sum(s>eta);

% I am not sure if necessary
if R<R_min || R>R_max
%     warning('rank out of range!');
end
R = max(R_min,R);
R = min(R_max,R);




function [xhat g] = cvx_min_hankel_rank_uncon(x,eta,omega)

[D,N] = size(x);
Ngap  = sum(omega==0);

nr = ceil(N/(D+1))*D;
nc = N - ceil(N/(D+1))+1;

xhat = x;


cvx_quiet(true);
cvx_clear;
cvx_begin sdp



    variable g(D,Ngap); % missing variables in x
    variable Y(nr,nr) symmetric;
    variable Z(nc,nc) symmetric;

    % interleaving knowns with unknowns
    idx = [1:N];
    idx(omega==0) = [N+1:N+Ngap];
    xgap = [x g];    
    xhat = xgap(:,idx);
    
    
    
    H = cvx_hankel_mo(xhat,[nr nc]);    
        
    minimize trace(Y) + trace(Z);  
    subject to
        [Y H;H' Z]>=0;
        
        
cvx_end
cvx_quiet(false);


35;


function [xhat g] = cvx_min_hankel_rank_con(x,eta,omega)

[D,N] = size(x);
Ngap  = sum(omega==0);

nr = ceil(N/(D+1))*D;
nc = N - ceil(N/(D+1))+1;

cvx_quiet(true);
cvx_clear;
cvx_begin sdp

    variable xhat(D,N); % missing variables in x
    variable Y(nr,nr) symmetric;
    variable Z(nc,nc) symmetric;

    % interleaving knowns with unknowns
%     idx = [1:N];
%     idx(omega==0) = [N+1:N+Ngap];
%     xgap = [x g];    
%     xhat = xgap(:,idx);
    
    
    
    H = cvx_hankel_mo(xhat,[nr nc]);    
        
    minimize trace(Y) + trace(Z);  
    subject to
        [Y H;H' Z]>=0;
        norm((x-xhat).*(ones(D,1)*omega),'fro')/sum(omega) <= eta;
cvx_end
cvx_quiet(false);

g = [];
35;