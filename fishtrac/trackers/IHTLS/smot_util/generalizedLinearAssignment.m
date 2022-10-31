function A = generalizedLinearAssignment(D,slackD)
[M N] = size(D);
% N = size(D,2);
if nargin <2
    slackD = 1e-2;
end

% WARNING: lapjv does not like inf values
% change inf values with something large
D(D==inf) = 1e15;

% Use slack variables to relax sum(X)==1,if they are very high they will be
% ommited.

D = [D  ones(M,M)*slackD ];
D = [D; ones(N,N+M)*slackD ];
[A,C] = lapjv(D);
A = A(1:M);
A(A>N) = 0;
35;

% TODO: Compute cost accordingly

