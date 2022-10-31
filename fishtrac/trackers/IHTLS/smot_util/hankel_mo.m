function varargout = hankel_mo(L,nrnc)


%   H = hankel_mo(X);
%
%   [H,D] = hankel_mo(X,nrnc);
%
%   X: Data DIMS x N 
%   nrnc: size of hankel matrix nr x nc
%   D: weight of each block in hankel matrix
%
% treat every column as a observation
% form a multi output hankel e.g.
%       | c1 c2 c3 |
% H =   | c2 c3 c4 |
%       | c3 c4 c5 |


[dim N] = size(L);

if dim>N
    warning('DIMS>N. Make sure X is DIMSxN (row vector)!')
end

if nargin<2
    % nr = ceil(N/2)*dim;
    nr = ceil(N/(dim+1))*dim;
    nc = N - ceil(N/(dim+1))+1;
else
    if(nrnc(1)==0)        
        % user input num of columns compute number of rows 
        nc = nrnc(2);
        nr = (N-nc+1)*dim;
    end
    if(nrnc(2)==0)
        % user input num of rows compute number of cols 
        nr = nrnc(1);
        nc = N - nr/dim + 1; 
        if mod(nr,dim)~=0
            error('Number of rows must be a multiple of input dimension');
        end
    end
    if (nrnc(1)>0 && nrnc(2)>0)
        nr = nrnc(1);
        nc = nrnc(2);
    end
end

if nargout == 2
    nb = nr/dim;
    l = min(nb,nc);
    D = [1:l-1 l*ones(1,N-2*l+2) l-1:-1:1];
end


% nc = N - ceil(N/(dim+1))+1;
% nc = N - (nr/dim)+1;



cidx = [0 : nc-1 ];
ridx = [1 : nr]';

H = ridx(:,ones(nc,1)) + dim*cidx(ones(nr,1),:);  % Hankel subscripts 
t = L(:);

temp.type = '()';
temp.subs = {H(:)};
H = reshape( subsref( t, temp ), size( H ) );

if nargout <= 1
    varargout = {H};
elseif nargout == 2
    varargout = {H,D};    
end