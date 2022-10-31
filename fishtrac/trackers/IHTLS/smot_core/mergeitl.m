function itl1 = mergeitl(itl1,itl2,param)

% merge itl1-->itl2 1: past 2: future

% or itl2 into itl1

gap = itl2.t_start - itl1.t_end - 1;
rank12 = [];

interpolation = 2;
% end-to-end
if gap >= 0    
       
    % do an interpolation temporarily. This will be overwritten, it mainly
    % serves visual purposes. 
    switch interpolation
        case 1  % just put nan
            int_xy = nan(2,gap);            
            itl1.data = [itl1.data int_xy itl2.data];
        case 2  % first order interpolation 
            dxy = (itl1.data(:,end) - itl2.data(:,1) )/(gap+1);
            int_xy = itl1.data(:,end)*ones(1,gap) - dxy * [1:gap];
            itl1.data = [itl1.data int_xy itl2.data];
        case 3  % min rank interpolation
            xy12      = [itl1.data zeros(2,gap) itl2.data];
            omega12  = [itl1.omega zeros(1,gap) itl2.omega];
            [xy12_hat,~,~,rank12] = incremental_hstln_mo(xy12,param.eta_max,...
                'omega',omega12,...
                'minrank',min(itl1.rank,itl2.rank),...
                'maxrank',itl1.rank+itl2.rank);
%             int_xy = xy12_hat(:,itl1.length+1:itl1.length+gap);
%             t_xy = [itl1.xy zeros(2,gap) itl2.xy];
            itl1.data = bsxfun(@times,xy12,omega12) + bsxfun(@times,xy12_hat,(1-omega12));
    end
    
    % itl1.rect   = [itl1.rect int_rect itl2.rect];
    itl1.t_end  = itl2.t_end;
    itl1.length = itl1.length + itl2.length + gap;
    
    % itl1.xy_end = itl2.xy_end;
    itl1.omega = [itl1.omega zeros(1,gap) itl2.omega];

% into 
elseif (itl2.t_start > itl1.t_start ) && (itl2.t_end < itl1.t_end)
    rt_start = itl2.t_start - itl1.t_start + 1;
    rt_end = rt_start + itl2.length - 1;
    
    itl1.data(:,rt_start:rt_end) = itl2.data;
    itl1.omega(rt_start:rt_end) = itl2.omega;
end

if isfield(itl1,'rank')
    itl1.rank = rank12;
end
