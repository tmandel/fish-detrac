function s = smot_similarity_binlong(x1,x2,gap)



[D1, N1] = size(x1);
[D2, N2] = size(x2);

if D1 ~= D2
    error('Input dimensions do not agree. They should have same number of columns!');
end

%%%% TRYYY
% extend the data with time tag
x1 = [x1;1:N1];
x2 = [x2;N1+gap+(1:N2)];
D1 = D1+1;
D2 = D2+1;
%%%%% TRYYYYY

% compute max column size
N = max(N1,N2);
D = D1;
nr = ceil(N/(D+1))*D;
nc = N - ceil(N/(D+1))+1;

% check if row size agrees with short tracklet
nr = min([nr N1 N2]);
nr = floor(nr/D)*D;

% form the Hankel matrices
% hankel_mo will automatically calculate number of columns
H1 = hankel_mo(x1,[nr 0]);
H2 = hankel_mo(x2,[nr 0]);
% H12 = [H1 H2];

H1h = H1 / norm(H1*H1','fro').^(1/2);
H2h = H2 / norm(H2*H2','fro').^(1/2);

[U1 S1 V1] = svd(H1h);
[U2 S2 V2] = svd(H2h);

% TRY 1
U1h = U1*S1;
U2h = U2*S2;
s = subspace(U1h,U2h);
 
% TRY 2


% H12h = H12 / norm(H12*H12','fro');

% if N1>N2
%     H1h = H1 / norm(H1*H1','fro');
%     s = norm(H12h*H12h' + H1h*H1h');
% else
%     H2h = H2 / norm(H2*H2','fro');
%     s = norm(H12h*H12h' + H2h*H2h');
% end
