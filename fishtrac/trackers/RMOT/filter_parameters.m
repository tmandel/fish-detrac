% filter parameters

% Modeling
% paramters for object motion
param.F = [1 0 1 0 0 0;
    0 1 0 1 0 0;
    0 0 1 0 0 0;
    0 0 0 1 0 0;
    0 0 0 0 1 0;
    0 0 0 0 0 1];
% ETH
param.Q = 1*[5 0 0 0;0 5 0 0;0 0 10 0;0 0 0 15].^2;
param.R = [1 0 0 0;0 1 0 0;0 0 3 0;0 0 0 3].^2;
param.G = [1/2 0 0 0;
    0 1/2 0 0;
    1 0 0 0;
    0 1 0 0;
    0 0 1 0;
    0 0 0 1];
param.H = [1 0 0 0 0 0;0 1 0 0 0 0;0 0 0 0 1 0;0 0 0 0 0 1];
param.P = [2 0 0 0 0 0;0 2 0 0 0 0;0 0 2 0 0 0;0 0 0 2 0 0;0 0 0 0 2 0;0 0 0 0 0 2].^2;


% paramters for relational function
param.Fr = [1 0 1 0;0 1 0 1;0 0 1 0;0 0 0 1];
param.Qr = [1 0;0 1].^2;
param.Rr = [5 0;0 5].^2;
param.Gr = [1/2 0;
    0 1/2;
    1 0;
    0 1];
param.Hr = [1 0 0 0;0 1 0 0];