function H = cvx_hankel_mo(L,nrnc)

[dim N] = size(L);

if nargin<2
    % nr = ceil(N/2)*dim;
    nr = ceil(N/(dim+1))*dim;
    nc = N - ceil(N/(dim+1))+1;
else
    nr = nrnc(1);
    nc = nrnc(2);
end

cidx = [0 : nc-1 ];
ridx = [1 : nr]';

H = ridx(:,ones(nc,1)) + dim*cidx(ones(nr,1),:);  % Hankel subscripts 
t = L(:);

H = reshape( cvx_subsref( t, H( : ) ), size( H ) );

