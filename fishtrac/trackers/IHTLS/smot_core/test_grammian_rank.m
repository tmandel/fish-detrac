N = 5;
x = [1:N];
omega = ones(1,N);

% x(5) = 0;
% omega(5) = 0;
x(4) = 0;
omega(4) = 0;

Hx = hankel_mo(x);
Ho = hankel_mo(omega);

Gx = Hx'*Hx;
Go = Ho'*Ho;

svd(Hx) 
svd(Gx./Go)