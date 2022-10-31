function [s rank1 rank2 rank12] = smot_similarity(x1,x2,eta,varargin)

% INPUTS:
% x1: trajectory 1 DxT (past)
% x2: trajectory 2 DxT (future)
%   D: dimension of the signal
%   T: length of the signal
% eta: noise estimate (std of noise)
%
% OPTIONS:
% gap    : gap between x1 and x2
% omega1 : used for unknown points in the trajectory
% omega2 : used for unknown points in the trajectory
% rank1  : rank of x1. if known saves time.
% rank2  : rank of x2. if known saves time.
% type   : distance type (hstln default)
% qcheck : quick check if trajectories are dynamically compatible.
%          qcheck may void some real pairs.



[D1 T1 ]= size(x1);
[D2 T2 ]= size(x2);


% Some error checks
if D1 ~= D2
    error('Input dimensions do not agree. They should have same number of columns!');
end


% Do usual parameter parsing

% Defaults
% defMaxRank = min([nr nc]);
% defMinRank = 1;
defGap      = 0;
defOmega1   = ones(1,T1);
defOmega2   = ones(1,T1);
defRank1    = 0;
defRank2    = 0;
defMethod   = 'ihtls';
defQCheck   = false;
% defRankFunc = @smot_rank_ihtls;




% Check user input parameters
p = inputParser;

addParamValue(p,'gap',defGap,@isnumeric);
addParamValue(p,'omega1',defOmega1,@isnumeric);
addParamValue(p,'omega2',defOmega2,@isnumeric);
addParamValue(p,'rank1',defRank1,@isnumeric);
addParamValue(p,'rank2',defRank2,@isnumeric);
addParamValue(p,'method',defMethod,@ischar);
addParamValue(p,'qcheck',defQCheck,@islogical);
parse(p,varargin{:});

gap = p.Results.gap;
omega1 = p.Results.omega1;
omega2 = p.Results.omega2;
rank1 = p.Results.rank1;
rank2 = p.Results.rank2;
method = p.Results.method;
qcheck = p.Results.qcheck;

% smot_rank_func = @smot_rank_ihtls;
% smot_rank_func = @smot_rank_tao;

rank1 = [];
rank2 = [];
rank12 = [];

switch lower(method)
    case {'ihtls','ip','admm'}
        % TODO: set rank func here        
        smot_rank_func = str2func(['smot_rank_' method]);
        % Compute rank1 
        if isempty(rank1)
            rank1 = smot_rank_func(x1,eta,'omega',omega1);
        end
        % Compute rank2
        if isempty(rank2)
            rank2 = smot_rank_func(x2,eta,'omega',omega2);
        end
        
        % try early elimination
        if qcheck
            nr = min(T1-rank1,T2-rank2);
            % round 
            nr = floor(nr/D1)*D1;
            H1 = hankel_mo(x1,[nr 0]);
            H2 = hankel_mo(x2,[nr 0]);
            
            rank12 = sum(svd([H1 H2])>eta);
            
            if rank12 > (rank1+rank2)
                s = -inf;
                return;
            end
        end
        
        
        
        % Compute joint rank
        x12     = [x1 zeros(D1,gap) x2];
        omega12  = [omega1 zeros(1,gap) omega2];
        rank12   = smot_rank_func(x12,eta,'omega',omega12,...
            'minrank',min(rank1,rank2),...
            'maxrank',rank1+rank2);
        
        
        % Compute similarity measure
%         drank = rank12-max(rank1,rank2);
        % FIX: Sometimes drank<0
%         drank = max(0,drank);
%         s = 1 / (1+drank);
        % TAO
        s = (rank1+rank2)/rank12 - 1;
        % TRY
%         drank = rank12-max(rank1,rank2);
%         s = 1 - drank/min(rank1,rank2);
        
        if s < 1e-5
            s = -inf;
        end
        
        
    case 'binlong'
        s = smot_similarity_binlong(x1,x2,gap);
%     case 'svd',
%     case 'subspace',
%     case 'cordeilla',
%     case 'grammian',
end



