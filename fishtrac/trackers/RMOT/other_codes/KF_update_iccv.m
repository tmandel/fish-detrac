function [var_xp]=KF_update_iccv(meas,var_xp,R,H)

N = size(var_xp.X,1);

X = var_xp.X;
P = var_xp.P;

% cov_dist = diag(meas(3:4)/2 + X(5:6)/2).^2;
% Rcov = [cov_dist, zeros(2,2);zeros(2,2), R(3:4,3:4)];

% S = H*P*H' + Rcov;
S = H*P*H' + R;
K = P*H'*inv(S);
X = X + K*(meas-H*X);
P = (eye(N)-K*H)*P;


var_xp.X = X;
var_xp.P = P;
% var_xp.X_set = [var_xp.X_set X];