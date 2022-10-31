function [itl etime]= smot_associate_itl(itl,param)

tic;

W = param.hor;
T_start = min([itl.t_start]);
T_end   = max([itl.t_end]);



% WARNING: Poor coding practice below. for loops might be combined in a
% better way.

% Do windowed stitching

% PASS I
fprintf('pass 1 is in progress\n');
for t = T_start : W : T_end-1

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
fprintf('pass 2 is in progress\n');
for t = T_start+floor(W/2)-1 : W : T_end-1

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

if 0
% PASS III
% Last pass with a twice the horizon
fprintf('final pass, might take more time than previous passes!\n');
W = W*2;
for t = T_start : W : T_end-1

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

end

etime = toc;
% % do a final association among windows
% % FIX: eliminate very small tracklets, we do not need them.
% % They are error prone at this stage
% len = [itl.length];
% itl(len<=2) = [];
%
% itl = associate_itl(itl,param);
%
% figure(1)
% drawidl(idl);
%
% figure(2)
% drawitl(itl);