function [itl, etime]= smot_associate(idl,param)

tic;
T = size(idl,2);
W = param.hor;


% generate initial tracklets
if isfield(param,'mu')
    itl = idl2itl_psu(idl,param.conflict_ratio,param.mu);
else
    itl = idl2itl(idl);
end

% FIX: Naming data is more appropriate than xy, because we might have
% multidimensions
% itl.data = itl.xy;
% itl = rmfield(itl,'xy');

% grow the tracklets
if 1
    itl = growitl(itl,param.eta_max);
end


% WARNING: Poor coding practice below. for loops might be combined in a
% better way. 

% Do windowed stitching 

% PASS I
% fprintf('pass 1 is in progress\n');
for t = 1:W:T-1
    
    if param.debug
        figure(2)
        drawitl(itl);
    end

    % apply association
    % FIX: eliminate very small tracklets, we do not need them.
    % They are error prone at this stage
    len = [itl.length];
    itl(len<=2) = [];    
    itl = associate_itl(itl,param,[t t+W-1]);
end
% PASS II
% fprintf('pass 2 is in progress\n');
for t = floor(W/2):W:T-1
    
    if param.debug
        figure(2)
        drawitl(itl);
    end

    % apply association
    % FIX: eliminate very small tracklets, we do not need them.
    % They are error prone at this stage
    len = [itl.length];
    itl(len<=2) = [];
    itl = associate_itl(itl,param,[t t+W-1]);
end


% PASS III
% Last pass with a twice the horizon
% fprintf('final pass, might take more time than previous passes!\n');
W = W*2;
for t = 1:W:T-1
    
    if param.debug        
        figure(2)
        drawitl(itl);
    end

    % apply association
    % FIX: eliminate very small tracklets, we do not need them.
    % They are error prone at this stage
    len = [itl.length];
    itl(len<=4) = [];
    itl = associate_itl(itl,param,[t t+W-1]);
end

etime = toc;