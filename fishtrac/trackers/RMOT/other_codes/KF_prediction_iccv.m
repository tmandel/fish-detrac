function [var_xp]=KF_prediction_iccv(var_xp,F,Q,G)
X = var_xp.X;
P = var_xp.P;

X = F*X;
P = F*P*F' +G*Q*G';

var_xp.X = X;
var_xp.P = P;