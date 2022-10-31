function R = smot_rank_ihtls(u,eta_max,varargin)

[D_u,N_u] = size(u);

nr = ceil(N_u/(D_u+1))*D_u;
nc = N_u - ceil(N_u/(D_u+1))+1;

defMaxRank = min([nr nc]);
defMinRank = 1;
defOmega   = ones(1,N_u);

% Check user input parameters
p = inputParser;

addParamValue(p,'maxrank',defMaxRank,@isnumeric);
addParamValue(p,'minrank',defMinRank,@isnumeric);
addParamValue(p,'omega',defOmega,@isnumeric);
parse(p,varargin{:});


R_max = p.Results.maxrank;
R_max = min([nr nc R_max]);
R_min = p.Results.minrank;
Omega = p.Results.omega;

% TRY to estimate minimum rank(save time)
% WARNING: This might be problematic because this does not consider missing
% values!
H = hankel_mo(u);
s = svd(H);
HnormFrosq = sum(s.^2);
Hnorm2sq = s(1).^2;
HnormNucsq = sum(s)^2;
R_FroI2 = floor(HnormFrosq/Hnorm2sq);
R_NucIFro = floor(HnormNucsq/HnormFrosq);
R_Heuristic = 0; %sum(s>s(1)*0.1);  % useless

% if (R_min < R_FroI2) || (R_min<R_NucIFro)
%     35;
% end

% WARNING: This step is problematic especially when inpainting needed
% R_min = max([R_min R_FroI2 R_NucIFro R_Heuristic]);



warning('off','MATLAB:rankDeficientMatrix');
x = zeros(1,R_min);
eta = zeros(D_u,N_u);
for R=R_min:R_max    
    
    [u_hat,eta,x,av_eta] = fast_hstln_mo(u,R,'omega',Omega,...
                    'maxiter',100,'tol',1e-4);
     
    % Warm start with previous estimates
%     [u_hat,eta,x,av_eta] = hstln_mo(u,R,'omega',Omega,...
%                     'maxiter',100,'tol',1e-4,...
%                     'x0',x,'eta',eta); % to speed it up
%     x = [x;min(x)/10]; 

    % recalculate average eta
    av_eta  = norm(bsxfun(@times,eta,Omega),'fro')/sum(Omega);

    if av_eta < eta_max
        break;
    end    

end
warning('on','MATLAB:rankDeficientMatrix');

