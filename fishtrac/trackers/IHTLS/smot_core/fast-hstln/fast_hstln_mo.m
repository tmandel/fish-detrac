function [u_hat,eta,x,mu_eta] = fast_hstln_mo(u,R,varargin)
% function [u_hat,eta,x] = hstln_mo(u,R,x0,Omega)
% 
% Hankel Structured Total Least Squares (HSTLN)
%   Fits an order R system to the input vector using HSTLN formula
%       (A+E)x = b+f
%
% Inputs:
%       U:  D times N input vector (D: dimension N: length)
%       R:  order of the fit
%       x0 (Optional):   initial AR coefficients
%       Omega(Optional): 0/1 sampling vector(use this if you miss 
%                        data samples or do not trust some of them)
% Outputs:
%       U_h: D times N output vector (filtered output)
%       eta: corrections (negative estimated noise)
%       x:   AR coefficients
%       
%
%
%   Written by Caglayan Dicle, 07/22/11 based on the paper:  
%   I. Park, L. Zhang and J.B. Rosen   "Low rank approximation of
%          a Hankel matrix by structured total least norm" 

[D_u,N_u] = size(u);

% Default parameters
defTol     = 1e-7;
defMaxIter = 100;
defOmega   = ones(1,N_u);
defx0      = [];
defEta     = zeros(D_u,N_u);
w = 1e8;


% Check user input parameters
p = inputParser;

addParamValue(p,'tol',defTol,@isnumeric);
addParamValue(p,'maxiter',defMaxIter,@isnumeric);
addParamValue(p,'omega',defOmega,@(x) (isnumeric(x) & ~isempty(x)) );
addParamValue(p,'x0',defx0,@isnumeric);
addParamValue(p,'eta',defEta,@isnumeric);

parse(p,varargin{:});

tol = p.Results.tol;
maxiter = p.Results.maxiter;
Omega = p.Results.omega;
x0 = p.Results.x0;
eta = p.Results.eta;



nc = R+1;
nr = (N_u-nc+1)*D_u;

% use indexing for hankels
hi = [1:D_u*N_u];
hi = reshape(hi,[D_u N_u]);
hi = hankel_mo(hi,[nr nc]);




% make the input sequence hankel
% Ab = mex_hankel_mo(u,[nr nc]);
Ab = u(hi); % fast indexing (hopefully)
% [Ab,d] = hankel_mo(u,[nr nc]);


% WARNING: check this!!!
d = ones(1,N_u);

A = Ab(:,1:end-1);
b = Ab(:,end);


% initializations
% WARNING. Pay attention below. eta overwrites x0.
% if ~isequal(eta,eta*0)
%     Ef = hankel_mo(eta,[nr nc]);
%     E = Ef(:,1:end-1);
%     f = Ef(:,end);
%     x0 = (A+E)\(b+f);
% end

if ~isempty(x0) 
    x = x0;
else
    x = A\b;
end

P1 = [zeros(nr,R*D_u) eye(nr,nr) ];
P1 = sparse(P1);
% P0 = [eye((N_u-1)*D_u) zeros((N_u-1)*D_u,D_u)];

eta = reshape(eta,[D_u*N_u 1]);


% if ~isempty(Omega)
    % remember D is multiplying eta
    D = diag(reshape(repmat(Omega,[D_u 1]),size(eta)));
    D = sparse(D);
%     D = diag(reshape(repmat(1./d.*Omega,[D_u 1]),size(eta)));    % this gives same importance to all samples
% else
%     D = diag(reshape(repmat(ones(1,N_u),[D_u 1]),size(eta)));
% end
% else
%     D = eye(N_u*D_u);
%     D = diag(reshape(repmat(d,[D_u 1]),size(eta)));
%     D = diag(reshape(repmat(1./d,[D_u 1]),size(eta)));

% end
%!!!
Yrow = zeros(1,D_u*(N_u-1));
YP0 = sparse(nr,D_u*N_u);
ti = 1:nr+1:nr*nr;
% E = zeros(nr,nc-1);

M = sparse(nr+D_u*N_u,D_u*N_u+R);

lastwarn('');
for iter=1:maxiter
    
    % form matrices 
%     E   = hankel_mo(reshape(eta,size(u)),[nr nc-1]);
    E = eta(hi(:,1:end-1)); % fast indexing (hopefully)
    
    % TODO: construct this better
    for j=1:R
        YP0(ti+ (j-1)*D_u*nr) = x(j);
    end
    
%     Yrow(1:D_u:D_u*R) = x';
%     Y = toeplitz([Yrow(1,1);zeros(nr-1,1)], Yrow );
    % Y*P0 = [Y|0]
%     YP0 = [Y zeros(nr,D_u)];
    
    
    f   = eta(end-nr+1:end);
    
    % compute r
    r = b+f - (A+E)*x;
    
    % form M    
%     M = [ w*(P1-YP0) -w*(A+E);...
%            D  zeros(N_u*D_u,R) ];
%     M = sparse(M);    
    M(1:nr,1:D_u*N_u) = w*(P1-YP0);
    M(1:nr,D_u*N_u+1:D_u*N_u+nc-1) = -w*(A+E);
    M(nr+1:end,1:D_u*N_u) = D;
    
    % solve minimization problem 
    try
        dparam = M\(-[w*r;D*eta]);
        error(lastwarn);
    catch err
        [warnmsg,~] = lastwarn;
        if isequal(warnmsg,'MATLAB:rankDeficientMatrix')
%         if ~isempty(lastwarn)
            lastwarn('');
            break;
        end        
    end
%     end
    
    % update parameters
    deta = dparam(1:N_u*D_u,1);
    dx   = dparam(N_u*D_u+1:end,1);
    
    eta = eta + deta;
    x = x +dx;
    
    % check convergence
%     norm_func = norm([w*r;D*eta]);
    norm_dparam = norm(dparam);
    
%     fprintf('iteration:%d norm_dparam:%g norm_func:%g\n',iter,norm_dparam,norm_func);
    
    if 0
        figure(11)
%         plot([u' (u+reshape(eta,size(u)))']);
        plot(u','k.');hold on;
        plot(u+reshape(eta,size(u))','g-');
    end
    
    if norm_dparam <tol
        break;
    end    
end
eta = reshape(eta,size(u));
u_hat = u + eta;
mu_eta = norm(eta.*repmat(1.*Omega,[D_u 1]),'fro')/(sum(Omega)*D_u);
% iter
if 0
    figure(51)
    plot([u' u_hat']);
%     plot([u(2,:)' u_hat(2,:)'])    
end
35;

