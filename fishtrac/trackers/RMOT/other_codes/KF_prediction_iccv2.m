function [X,P]=KF_prediction_iccv2(X,P,F,Q,G)

X = F*X;
P = F*P*F' +G*Q*G';

