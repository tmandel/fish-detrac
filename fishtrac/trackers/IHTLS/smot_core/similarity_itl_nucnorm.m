function [s r1 r2 r12] = similarity_itl_hstln(itl1,itl2,eta_max,varargin)

defMaxHorizon = inf;
defMaxGap = inf;

% Check user input parameters
p = inputParser;

addParamValue(p,'maxhorizon',defMaxHorizon,@isnumeric);
addParamValue(p,'maxgap',defMaxGap,@isnumeric);
parse(p,varargin{:});


hor_max = p.Results.maxhorizon;
gap_max = p.Results.maxgap;


% check if they are compatible
% two options 
% 1) if itl2 comes later than itl1
% 2) if itl2 goes into itl1

% check if they have ranks computed
if isempty(itl1.rank)
    if itl1.length < 2
        r1 = 1;
    else
        [~,~,~,r1] = incremental_hstln_mo(itl1.xy,eta_max,'omega',itl1.omega);
    end
else
    r1 = itl1.rank;
end

if isempty(itl2.rank)
    if itl2.length < 2
        r2 = 1;
    else
        [~,~,~,r2] = incremental_hstln_mo(itl2.xy,eta_max,'omega',itl2.omega);
    end
else
    r2 = itl2.rank;
end

s = -inf;
r12 = inf;


gap = itl2.t_end - itl1.t_start - 1;

if gap >= 0 && gap < gap_max
    % itl2 comes after itl1    
        
    % compute joint rank
    rmax = r1+r2;
    [~,~,~,r12] = incremental_hstln_mo([itl1.xy zeros(2,gap) itl2.xy],eta_max,...
                                 'minrank',min(r1,r2),...
                                 'maxrank',rmax,...
                                 'omega',[itl1.omega zeros(1,gap) itl2.omega]);
    
    s = (r1+r2)/r12 - 1;
    
    
elseif (itl2.t_start > itl1.t_start ) && (itl2.t_end < itl1.t_end)
    % itl2 may be a missing part for itl1
    % check omegas now
    35;
else
    
end


