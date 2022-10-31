function [s r1 r2 r12] = similarity_itl(itl1,itl2,eta_max,varargin)


defMaxHorizon = inf;
defMaxGap = inf;
defMaxSlope = inf;
defMethod = 'ihtls';

% Check user input parameters
p = inputParser;

addParamValue(p,'maxhorizon',defMaxHorizon,@isnumeric);
addParamValue(p,'maxgap',defMaxGap,@isnumeric);
addParamValue(p,'maxslope',defMaxSlope,@isnumeric);
addParamValue(p,'method',defMethod,@ischar);
parse(p,varargin{:});


hor_max = p.Results.maxhorizon;
gap_max = p.Results.maxgap;
slope_max = p.Results.maxslope;
method = p.Results.method;



% check if they are compatible
% two options 
% 1) if itl2 comes later than itl1
% 2) if itl2 goes into itl1

%% Individual Ranks
r1 = itl1.rank;
r2 = itl2.rank;
r12 = inf;
s = -inf;
r12 = inf;

% If they are both very short tracklets they are unreliable
if itl1.length <= 2 && itl2.length <= 2 
    return;
end


%% Joint Rank

gap = itl2.t_start - itl1.t_end - 1;
slope = norm(itl2.data(:,1) - itl1.data(:,end),'fro')/(gap+1);

% HEURISTIC: avoid very large gaps, very sharp slopes 

if gap >= 0 && gap < gap_max && slope < (slope_max*2)
    % itl2 comes after itl1        
    
    [s r1 r2 r12] = smot_similarity(itl1.data,itl2.data,eta_max,...
        'gap',gap,...
        'rank1',itl1.rank,'rank2',itl2.rank,...
        'omega1',itl1.omega,'omega2',itl2.omega,...
        'method',method);
    
    


    
    
elseif 0 & (itl2.t_start > itl1.t_start ) && (itl2.t_end < itl1.t_end)
    % itl2 may be a missing part for itl1
    % check omegas now
    rt_start = itl2.t_start - itl1.t_start + 1;
    rt_end = rt_start + itl2.length - 1;
    if sum(itl1.omega(rt_start:rt_end)==0) == itl2.length
        % compute the joint rank
        rmax = r1+r2;
        
        % TODO: Rewrite the following
        [s r1 r2 r12] = smot_similarity([itl1.data(:,1:rt_start-1) itl2.data itl1.data(:,rt_end+1:end)],eta_max,...
                                 'gap',gap,...
                                 'rank1',itl1.rank,'rank2',itl2.rank,...
                                 'omega1',itl1.omega,'omega2',itl2.omega);
                                 
                             %'omega',[itl1.omega(1:rt_start-1) itl2.omega itl1.omega(rt_end+1:end)]);

        
    end
    
    
else
    
end
