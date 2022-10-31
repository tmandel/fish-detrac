function distance = distance_sq(X,Y)

% X and Y is DxN

NY = size(Y,2);
NX = size(X,2);


X2 = sum(X.^2,1);
Y2 = sum(Y.^2,1);


distance = repmat(X2',1,NY) + repmat(Y2,NX,1) - 2*X'*Y;
