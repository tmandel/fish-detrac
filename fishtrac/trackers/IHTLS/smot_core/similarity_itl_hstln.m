function [s r1 r2 r12] = similarity_itl_hstln(itl1,itl2,eta_max,varargin)

defMaxHorizon = inf;
defMaxGap = inf;
defMaxSlope = inf;

% Check user input parameters
p = inputParser;

addParamValue(p,'maxhorizon',defMaxHorizon,@isnumeric);
addParamValue(p,'maxgap',defMaxGap,@isnumeric);
addParamValue(p,'maxslope',defMaxGap,@isnumeric);
parse(p,varargin{:});


hor_max = p.Results.maxhorizon;
gap_max = p.Results.maxgap;
slope_max = p.Results.maxslope;


% check if they are compatible
% two options 
% 1) if itl2 comes later than itl1
% 2) if itl2 goes into itl1

%% Individual Ranks
% check if they have ranks computed
if isempty(itl1.rank)
    if itl1.length <= 2
        r1 = itl1.length;
    else
        xy = itl1.xy;
        xy(isnan(xy)) = 0;
        [~,~,~,r1] = incremental_hstln_mo(xy,eta_max,'omega',itl1.omega);
    end
else
    r1 = itl1.rank;
end

if isempty(itl2.rank)
    if itl2.length <= 2
        r2 = itl2.length;
    else
        xy = itl2.xy;
        xy(isnan(xy)) = 0;
        [~,~,~,r2] = incremental_hstln_mo(xy,eta_max,'omega',itl2.omega);
    end
else
    r2 = itl2.rank;
end

s = -inf;
r12 = inf;

% If they are both very short tracklets they are unreliable
if itl1.length <= 2 && itl2.length <= 2 
    return;
end


%% Joint Rank

gap = itl2.t_start - itl1.t_end - 1;
slope = norm(itl2.xy(:,1) - itl1.xy(:,end),'fro')/(gap+1);

if gap >= 0 && gap < gap_max && slope < (slope_max*2)
    % itl2 comes after itl1        
    
    
    % compute joint rank
    rmax = r1+r2;
    [~,~,~,r12] = incremental_hstln_mo([itl1.xy zeros(2,gap) itl2.xy],eta_max,...
                                 'minrank',max(r1,r2),...
                                 'maxrank',rmax,...
                                 'omega',[itl1.omega zeros(1,gap) itl2.omega]);
    
%     s = (r1+r2)/r12 - 1;
%     s = max(r1,r2)/r12;
    s = 1 / (1+r12-max(r1,r2));
    
    
elseif (itl2.t_start > itl1.t_start ) && (itl2.t_end < itl1.t_end)
    % itl2 may be a missing part for itl1
    % check omegas now
    rt_start = itl2.t_start - itl1.t_start + 1;
    rt_end = rt_start + itl2.length - 1;
    if sum(itl1.omega(rt_start:rt_end)==0) == itl2.length
        % compute the joint rank
        rmax = r1+r2;
        [~,~,~,r12] = incremental_hstln_mo([itl1.xy(:,1:rt_start-1) itl2.xy itl1.xy(:,rt_end+1:end)],eta_max,...
                                 'minrank',max(r1,r2),...
                                 'maxrank',rmax,...
                                 'omega',[itl1.omega(1:rt_start-1) itl2.omega itl1.omega(rt_end+1:end)]);
                             
%         s = (r1+r2)/r12 - 1;
%         s = max(r1,r2)/r12;
        s = 1 / (1+r12-max(r1,r2));
        35;
        
    end
    
    
else
    
end



