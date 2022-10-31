function D = mahal2(X,Y,Distance,DistParameter)

SIGMA=DistParameter;
INVSIG=inv(SIGMA);
MU=mean(Y);
m = size(X,1);%rows (X);
n = size(Y,1);%%rows (Y);
mOnes = ones (1, m);
D = zeros (m, n);
for k = 1:m
    for j = 1:n
        D(k,j) = (X(k,:)-Y(j,:))*INVSIG*(X(k,:)-Y(j,:))';
    end
end

D = sqrt(D);
