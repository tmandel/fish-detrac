function [MM,PP] = km_estimation(X,Y,param,P)
% X: object motion state, (x_pos, x_vel, y_pos, y_vel)
% Y: measurements, (x_pos, y_pos)

%% Copyright (C) 2014 Seung-Hwan Bae
%% All rights reserved.

if nargin <4
    P = param.P;
    
end
H = param.H;
R = param.R;


Ts = param.Ts;
F1 = [1 Ts;0 1]; 
Fz = zeros(2,2); 
param.F = [F1 Fz;Fz F1]; 


A = param.F;
Q = param.Q;

if ~isempty(Y)
    [MM,PP] = kf_loop(X,P,H,R,Y,A,Q);
else
    [MM,PP] = kf_predict(X,P,A,Q);
end

end