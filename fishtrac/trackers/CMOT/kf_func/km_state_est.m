function [MM,PP] = km_state_est(X,Y,param,P)
%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

% X: object motion state, (x_pos, x_vel, y_pos, y_vel)
% Y: measurements, (x_pos, y_pos)

if nargin <4
    P = param.P;
end
H = param.H;
R = param.R;
A = param.F;
Q = param.Q;

if ~isempty(Y)
    [MM,PP] = kf_loop(X,P,H,R,Y,A,Q);
else
    [MM,PP] = kf_predict(X,P,A,Q);
end

end
