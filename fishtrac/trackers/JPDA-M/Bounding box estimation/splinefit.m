function pp = splinefit(varargin)
%SPLINEFIT Fit a spline to noisy data.
%   PP = SPLINEFIT(X,Y,BREAKS) fits a piecewise cubic spline with breaks
%   (knots) BREAKS to the noisy data (X,Y). X is a vector and Y is a vector
%   or an ND array. If Y is an ND array, then X(j) and Y(:,...,:,j) are
%   matched. Use PPVAL to evaluate PP.
%
%   PP = SPLINEFIT(X,Y,P) where P is a positive integer interpolates the
%   breaks linearly from the sorted locations of X. P is the number of
%   spline pieces and P+1 is the number of breaks.
%
%   OPTIONAL INPUT
%   Argument places 4 to 8 are reserved for optional input.
%   These optional arguments can be given in any order:
%
%   PP = SPLINEFIT(...,'p') applies periodic boundary conditions to
%   the spline. The period length is MAX(BREAKS)-MIN(BREAKS).
%
%   PP = SPLINEFIT(...,'r') uses robust fitting to reduce the influence
%   from outlying data points. Three iterations of weighted least squares
%   are performed. Weights are computed from previous residuals.
%
%   PP = SPLINEFIT(...,BETA), where 0 < BETA < 1, sets the robust fitting
%   parameter BETA and activates robust fitting ('r' can be omitted).
%   Default is BETA = 1/2. BETA close 0 gives all data equal weighting.
%   Increase BETA to reduce the influence from outlying data. BETA close
%   to 1 may cause instability or rank deficiency.
%
%   PP = SPLINEFIT(...,N) sets the spline order to N. Default is a cubic
%   spline with order N = 4. A spline with P pieces has P+N-1 degrees of
%   freedom. With periodic boundary conditions the degrees of freedom are
%   reduced to P.
%
%   PP = SPLINEFIT(...,CON) applies linear constraints to the spline.
%   CON is a structure with fields 'xc', 'yc' and 'cc':
%       'xc', x-locations (vector)
%       'yc', y-values (vector or ND array)
%       'cc', coefficients (matrix).
%
%   Constraints are linear combinations of derivatives of order 0 to N-2
%   according to
%
%     cc(1,j)*y(x) + cc(2,j)*y'(x) + ... = yc(:,...,:,j),  x = xc(j).
%
%   The maximum number of rows for 'cc' is N-1. If omitted or empty 'cc'
%   defaults to a single row of ones. Default for 'yc' is a zero array.
%
%   EXAMPLES
%
%       % Noisy data
%       x = linspace(0,2*pi,100);
%       y = sin(x) + 0.1*randn(size(x));
%       % Breaks
%       breaks = [0:5,2*pi];
%
%       % Fit a spline of order 5
%       pp = splinefit(x,y,breaks,5);
%
%       % Fit a spline of order 3 with periodic boundary conditions
%       pp = splinefit(x,y,breaks,3,'p');
%
%       % Constraints: y(0) = 0, y'(0) = 1 and y(3) + y"(3) = 0
%       xc = [0 0 3];
%       yc = [0 1 0];
%       cc = [1 0 1; 0 1 0; 0 0 1];
%       con = struct('xc',xc,'yc',yc,'cc',cc);
%
%       % Fit a cubic spline with 8 pieces and constraints
%       pp = splinefit(x,y,8,con);
%
%       % Fit a spline of order 6 with constraints and periodicity
%       pp = splinefit(x,y,breaks,con,6,'p');
%
%   See also SPLINE, PPVAL, PPDIFF, PPINT

%   Author: jonas.lundgren@saabgroup.com, 2010.

%   2009-05-06  Original SPLINEFIT.
%   2010-06-23  New version of SPLINEFIT based on B-splines.
%   2010-09-01  Robust fitting scheme added.
%   2010-09-01  Support for data containing NaNs.
%   2011-07-01  Robust fitting parameter added.

% Check number of arguments
error(nargchk(3,8,nargin));

% Check arguments
[x,y,dim,breaks,n,periodic,beta,constr,weights,lad] = arguments(varargin{:});

% Evaluate B-splines
base = splinebase(breaks,n);
pieces = base.pieces;
A = ppval(base,x);

% Bin data
[junk,ibin] = histc(x,[-inf,breaks(2:end-1),inf]); %#ok

% Sparse system matrix
mx = numel(x);
ii = [ibin; ones(n-1,mx)];
ii = cumsum(ii,1);
jj = repmat(1:mx,n,1);
if periodic
    ii = mod(ii-1,pieces) + 1;
    A = sparse(ii,jj,A,pieces,mx);
else
    A = sparse(ii,jj,A,pieces+n-1,mx);
end

% Don't use the sparse solver for small problems
if pieces < 20*n/log(1.7*n)
    A = full(A);
end

% global randw;
% Solve
if isempty(constr)
    % Solve Min norm(u*A-y)
    %     weights=ones(size(x));
    normweights=weights/size(A,1);
    weightsmat=repmat(normweights,size(A,1),1);
    %     weightsmat
    %     pause
    %     randw
    %     A
    %     y
    
    %     [size(A) size(y)]
    
    %     size(u)
    %     pause
    if lad
%         u = ladsolve(A.*weightsmat,y.*weightsmat(1:dim,:),[]);
        u = ladwcwssolve(A.*weightsmat,y.*weightsmat(1:dim,:),breaks,n,pieces,base,dim,x);
%         u = lsqsolve(A.*weightsmat,y.*weightsmat(1:dim,:),beta);
    else
        u = lsqsolve(A.*weightsmat,y.*weightsmat(1:dim,:),beta);
        % TODO use csaps to fit with curvature
    end
% % %     if dim==2
% % %     ulad = ladsolve(A.*weightsmat,y.*weightsmat(1:dim,:),[]);
% % %     ulsq = lsqsolve(A.*weightsmat,y.*weightsmat(1:dim,:),beta);
% % %     uwc = ladwcsolve(A.*weightsmat,y.*weightsmat(1:dim,:),breaks,n,pieces,base,dim,x);
% % %     uwcws = ladwcwssolve(A.*weightsmat,y.*weightsmat(1:dim,:),breaks,n,pieces,base,dim,x);
% % %     end
    
    %     if length(x)>10
    %     u
    %     ulad
    %     ulsq
    %     uwc
    %     ulad-uwc
    %     pause
    %     end
    
    %     if tmpcnt<1000, save(sprintf('tmp/tmp%d/tmpvar_%05d.mat',processnr,tmpcnt),'*'); tmpcnt=tmpcnt+1; end
    %     u
    %
    %     u
    %     pause
    
    %     u=lsqsolve(A,y,beta);
    %     u
    %     pause
else
    % Evaluate constraints
    B = evalcon(base,constr,periodic);
    % Solve constraints
    [Z,u0] = solvecon(B,constr);
    % Solve Min norm(u*A-y), subject to u*B = yc
    y = y - u0*A;
    A = Z*A;
    v = lsqsolve(A,y,beta);
    u = u0 + v*Z;
end

% Periodic expansion of solution
if periodic
    jj = mod(0:pieces+n-2,pieces) + 1;
    u = u(:,jj);
end

% Compute polynomial coefficients
ii = [repmat(1:pieces,1,n); ones(n-1,n*pieces)];
ii = cumsum(ii,1);
jj = repmat(1:n*pieces,n,1);
C = sparse(ii,jj,base.coefs,pieces+n-1,n*pieces);
coefs = u*C;
coefs = reshape(coefs,[],n);

% Make piecewise polynomial
pp = mkpp(breaks,coefs,dim);

% %%%%%%%%%%%%%%%%%%%%%%%%%%
% % % if dim==2
% % % coefswc = uwc*C;
% % % coefswc = reshape(coefswc,[],n);
% % % 
% % % % Make piecewise polynomial
% % % ppwc = mkpp(breaks,coefswc,dim);
% % % 
% % % coefswcws = uwcws*C;
% % % coefswcws = reshape(coefswcws,[],n);
% % % 
% % % % Make piecewise polynomial
% % % ppwcws = mkpp(breaks,coefswcws,dim);
% % % 
% % % 
% % % % breaks
% % % % pp
% % % % ppwc
% % % if length(x)>30
% % %     figure(5)
% % %     clf
% % %     hold on
% % %     
% % %     % x
% % %     xnew=[x(1)-2 x(1)-1 x x(end)+1 x(end)+2];
% % % %     xval=linspace(xnew(1),xnew(end),100);
% % % %     pval=ppval(pp,xval);
% % % %     subplot(411)
% % % %     plot(xval,pval(1,:),'r','linewidth',3);
% % % %     subplot(412)
% % % %     plot(xval,pval(2,:),'r','linewidth',3);
% % %     % plot3(pval(1,:),pval(2,:),xval,'linewidth',3);
% % % %     global pp
% % %     
% % %     spc=getSplineCurvature(pp,x);
% % %     spcwc=getSplineCurvature(ppwc,x);
% % %     spcwcws=getSplineCurvature(ppwcws,x);
% % %     spsl=getSplineSlope(pp,x);
% % %     spslwc=getSplineSlope(ppwc,x);
% % %     spslwcws=getSplineSlope(ppwcws,x);
% % %     
% % %     x
% % %     spc
% % %     spcwc
% % %     % spc
% % %     pval2=ppval(pp,xnew);
% % %     
% % %     
% % %     subplot(413); hold on
% % %     plot(x,spc)
% % %     plot(x,spcwc,'k')
% % %     plot(x,spcwcws,'r');
% % % %     ylim([0 2e-1]);
% % % 
% % %     subplot(414); hold on
% % %     plot(x,spsl)
% % %     plot(x,spslwc,'k')
% % %     plot(x,spslwcws,'r')
% % %     legend(sprintf('total speed %.2f',sum(spsl)),sprintf('total speed wc %.2f',sum(spslwc)),sprintf('total speed wcws %.2f',sum(spslwcws)));
% % %     
% % %     xval=linspace(x(1),x(end),100);
% % %     pval=ppval(pp,xval);
% % %     subplot(411); hold on; %ylim([-14000 0]); 
% % %     xlim([xnew(1) xnew(end)]);
% % %     ylabel('x-component');    xlabel('frame #');
% % %     plot(xval,pval(1,:),'linewidth',3);
% % %     subplot(412); hold on; %ylim([-14000 0]); 
% % %     xlim([xnew(1) xnew(end)]);
% % %     ylabel('y-component');    xlabel('frame #');
% % %     plot(xval,pval(2,:),'linewidth',3);
% % %     % plot3(pval(1,:),pval(2,:),xval,'linewidth',3);
% % %     
% % %     rngx=max(pval(1,:))-min(pval(1,:));rngy=max(pval(2,:))-min(pval(2,:));
% % %     rngxy1=max(rngx,rngy);
% % %     
% % %     pval=ppval(ppwc,xval);
% % % 
% % %     rngx=max(pval(1,:))-min(pval(1,:));rngy=max(pval(2,:))-min(pval(2,:));
% % %     rngxy2=max(rngx,rngy);
% % %     rngxy=max(rngxy1,rngxy2);
% % % 
% % %     subplot(411); hold on; ylim([-14000 0]); ylim([mean(pval(1,:))-rngxy/2 mean(pval(1,:))+rngxy/2]);
% % %     xlim([xnew(1) xnew(end)]);
% % %     plot(xval,pval(1,:),'k','linewidth',1);
% % %     subplot(412); hold on; ylim([-14000 0]);  ylim([mean(pval(2,:))-rngxy/2 mean(pval(2,:))+rngxy/2]);
% % %     xlim([xnew(1) xnew(end)]);
% % %     plot(xval,pval(2,:),'k','linewidth',1);
% % %     
% % %     pval=ppval(ppwcws,xval);
% % % 
% % %     rngx=max(pval(1,:))-min(pval(1,:));rngy=max(pval(2,:))-min(pval(2,:));
% % %     rngxy2=max(rngx,rngy);
% % %     rngxy=max(rngxy1,rngxy2);
% % % 
% % %     subplot(411); hold on; ylim([-14000 0]); ylim([mean(pval(1,:))-rngxy/2 mean(pval(1,:))+rngxy/2]);
% % %     xlim([xnew(1) xnew(end)]);
% % %     plot(xval,pval(1,:),'r','linewidth',1);
% % %     subplot(412); hold on; ylim([-14000 0]);  ylim([mean(pval(2,:))-rngxy/2 mean(pval(2,:))+rngxy/2]);
% % %     xlim([xnew(1) xnew(end)]);
% % %     plot(xval,pval(2,:),'r','linewidth',1);
% % %     
% % %     
% % %     spc=getSplineCurvature(pp,x);
% % %     spcwc=getSplineCurvature(ppwc,x);
% % %     spc
% % %     spcwc
% % %     [spcsorted spcidx]=sort(spc,'descend');
% % %     [spcwcsorted spcwcidx]=sort(spcwc,'descend');
% % %     
% % %     % spc
% % %     pval2=ppval(pp,x);
% % %     pval2wc=ppval(ppwc,x);
% % %     pval2wcws=ppval(ppwcws,x);
% % %     maxtexts=10;
% % %     
% % %     for sss=1:maxtexts%length(spc)
% % %         ss=spcidx(sss);
% % %         subplot(411)
% % %         text(x(ss),pval2(1,ss)+50,sprintf('%.2f',1*spc(ss)),'Rotation',90,'color','b');
% % %         subplot(412)
% % %         text(x(ss),pval2(2,ss)+50,sprintf('%.2f',1*spc(ss)),'Rotation',90,'color','b');
% % %     end
% % %     
% % %     for sss=1:maxtexts%length(spc)
% % %         ss=spcwcidx(sss);
% % %         subplot(411)
% % %         text(x(ss),pval2wc(1,ss)-50,sprintf('%.2f',1*spcwc(ss)),'Rotation',90,'HorizontalAlignment','right');
% % %         subplot(412)
% % %         text(x(ss),pval2wc(2,ss)-50,sprintf('%.2f',1*spcwc(ss)),'Rotation',90,'HorizontalAlignment','right');
% % %     end
% % %     
% % %     subplot(413);xlim([xnew(1) xnew(end)]);
% % %     legend(sprintf('total curv %.2f',sum(spc)),sprintf('total cuwc %.2f',sum(spcwc)),sprintf('total cuwcsl %.2f',sum(spcwc)));
% % %     
% % %     % pval=ppval(pp,x);
% % %     % for ss=1:length(spc)
% % %     %     text(pval(1,ss)+10,pval(2,ss)+10,x(ss),sprintf('%5g',spc(ss)));
% % %     % end
% % %     
% % %     
% % %     % dots
% % % %     weights
% % %     subplot(411)
% % %     for pt=1:length(x)
% % %         plot(x(pt),y(1,pt),'o','MarkerSize',10*weights(pt));
% % %     end
% % %     subplot(412)
% % %     for pt=1:length(x)
% % %         plot(x(pt),y(2,pt),'o','MarkerSize',10*weights(pt));
% % %     end
% % %     
% % %     
% % % %     saveas(gca,'splinefit.pdf')
% % % %     pause
% % %     uinp=input('display? ','s');
% % %     if isequal(uinp,'y')
% % %         global sceneInfo opt
% % %         stInfo.F=51;
% % %         stInfo.opt=opt;
% % %         stInfo.frameNums=sceneInfo.frameNums;
% % %         
% % %         pp.start=max(1,x(1));        pp.end=min(stInfo.F,x(end));
% % %         ppwc.start=max(1,x(1));        ppwc.end=min(stInfo.F,x(end));
% % %         
% % %         allsp=[pp ppwc];
% % %         stInfo=getStateFromSplines(allsp,stInfo);
% % %         [stInfo.Xi stInfo.Yi]=projectToImage(stInfo.X,stInfo.Y,sceneInfo);
% % %         stInfo.H=70*ones(size(stInfo.X));
% % %         stInfo.W=stInfo.H/2;
% % %         displayTrackingResult(sceneInfo,stInfo);
% % %     end
% % % end
% % % end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%pp.bspline=pp2sp(pp);

%--------------------------------------------------------------------------
function [x,y,dim,breaks,n,periodic,beta,constr,weights,lad] = arguments(varargin)
%ARGUMENTS Lengthy input checking
%   x           Noisy data x-locations (1 x mx)
%   y           Noisy data y-values (prod(dim) x mx)
%   dim         Leading dimensions of y
%   breaks      Breaks (1 x (pieces+1))
%   n           Spline order
%   periodic    True if periodic boundary conditions
%   beta        Robust fitting parameter, no robust fitting if beta = 0
%   constr      Constraint structure
%   constr.xc   x-locations (1 x nx)
%   constr.yc   y-values (prod(dim) x nx)
%   constr.cc   Coefficients (?? x nx)
%   weights     weight vector for distances (Anton)
%   lad         flag for least absolute deviation (Anton)

% Reshape x-data
x = varargin{1};
mx = numel(x);
x = reshape(x,1,mx);

% Remove trailing singleton dimensions from y
y = varargin{2};
dim = size(y);
while numel(dim) > 1 && dim(end) == 1
    dim(end) = [];
end
my = dim(end);

% Leading dimensions of y
if numel(dim) > 1
    dim(end) = [];
else
    dim = 1;
end

% Reshape y-data
pdim = prod(dim);
y = reshape(y,pdim,my);

% Check data size
if mx ~= my
    mess = 'Last dimension of array y must equal length of vector x.';
    error('arguments:datasize',mess)
end

% Treat NaNs in x-data
inan = find(isnan(x));
if ~isempty(inan)
    x(inan) = [];
    y(:,inan) = [];
    mess = 'All data points with NaN as x-location will be ignored.';
    warning('arguments:nanx',mess)
end

% Treat NaNs in y-data
inan = find(any(isnan(y),1));
if ~isempty(inan)
    x(inan) = [];
    y(:,inan) = [];
    mess = 'All data points with NaN in their y-value will be ignored.';
    warning('arguments:nany',mess)
end

% Check number of data points
mx = numel(x);
if mx == 0
    error('arguments:nodata','There must be at least one data point.')
end

% Sort data
if any(diff(x) < 0)
    [x,isort] = sort(x);
    y = y(:,isort);
end

% Breaks
if isscalar(varargin{3})
    % Number of pieces
    p = varargin{3};
    if ~isreal(p) || ~isfinite(p) || p < 1 || fix(p) < p
        mess = 'Argument #3 must be a vector or a positive integer.';
        error('arguments:breaks1',mess)
    end
    if x(1) < x(end)
        % Interpolate breaks linearly from x-data
        dx = diff(x);
        ibreaks = linspace(1,mx,p+1);
        [junk,ibin] = histc(ibreaks,[0,2:mx-1,mx+1]); %#ok
        breaks = x(ibin) + dx(ibin).*(ibreaks-ibin);
    else
        breaks = x(1) + linspace(0,1,p+1);
    end
else
    % Vector of breaks
    breaks = reshape(varargin{3},1,[]);
    if isempty(breaks) || min(breaks) == max(breaks)
        mess = 'At least two unique breaks are required.';
        error('arguments:breaks2',mess);
    end
end

% Unique breaks
if any(diff(breaks) <= 0)
    breaks = unique(breaks);
end

% Optional input defaults
n = 4;                      % Cubic splines
periodic = false;           % No periodic boundaries
robust = false;             % No robust fitting scheme
beta = 0.5;                 % Robust fitting parameter
constr = [];                % No constraints
weights = ones(1,length(x)); % all ones weights
lad = false;                % LAD fit

% Loop over optional arguments
for k = 4:nargin
    a = varargin{k};
    if ischar(a) && isscalar(a) && lower(a) == 'p'
        % Periodic conditions
        periodic = true;
    elseif ischar(a) && isscalar(a) && lower(a) == 'r'
        % Robust fitting scheme
        robust = true;
    elseif ischar(a) && isscalar(a) && lower(a) == 'a'
        % l1 norm LAD fit
        lad = true;
    elseif ischar(a) && isscalar(a) && lower(a) == 's'
        % l2 norm LSQ fit
        lad = false;
    elseif isreal(a) && isscalar(a) && isfinite(a) && a > 0 && a < 1
        % Robust fitting parameter
        beta = a;
        robust = true;
    elseif isreal(a) && isscalar(a) && isfinite(a) && a > 0 && fix(a) == a
        % Spline order
        n = a;
    elseif isstruct(a) && isscalar(a)
        % Constraint structure
        constr = a;
    elseif all(size(x)==size(a))
        % weight vector
        weights=a;
    else
        error('arguments:nonsense','Failed to interpret argument #%d.',k)
    end
end

% No robust fitting
if ~robust
    beta = 0;
end

% Check exterior data
h = diff(breaks);
xlim1 = breaks(1) - 0.01*h(1);
xlim2 = breaks(end) + 0.01*h(end);
if x(1) < xlim1 || x(end) > xlim2
    if periodic
        % Move data inside domain
        P = breaks(end) - breaks(1);
        x = mod(x-breaks(1),P) + breaks(1);
        % Sort
        [x,isort] = sort(x);
        y = y(:,isort);
    else
        mess = 'Some data points are outside the spline domain.';
%         warning('arguments:exteriordata',mess)
    end
end

% Return
if isempty(constr)
    return
end

% Unpack constraints
xc = [];
yc = [];
cc = [];
names = fieldnames(constr);
for k = 1:numel(names)
    switch names{k}
        case {'xc'}
            xc = constr.xc;
        case {'yc'}
            yc = constr.yc;
        case {'cc'}
            cc = constr.cc;
        otherwise
            mess = 'Unknown field ''%s'' in constraint structure.';
            warning('arguments:unknownfield',mess,names{k})
    end
end

% Check xc
if isempty(xc)
    mess = 'Constraints contains no x-locations.';
    error('arguments:emptyxc',mess)
else
    nx = numel(xc);
    xc = reshape(xc,1,nx);
end

% Check yc
if isempty(yc)
    % Zero array
    yc = zeros(pdim,nx);
elseif numel(yc) == 1
    % Constant array
    yc = zeros(pdim,nx) + yc;
elseif numel(yc) ~= pdim*nx
    % Malformed array
    error('arguments:ycsize','Cannot reshape yc to size %dx%d.',pdim,nx)
else
    % Reshape array
    yc = reshape(yc,pdim,nx);
end

% Check cc
if isempty(cc)
    cc = ones(size(xc));
elseif numel(size(cc)) ~= 2
    error('arguments:ccsize1','Constraint coefficients cc must be 2D.')
elseif size(cc,2) ~= nx
    mess = 'Last dimension of cc must equal length of xc.';
    error('arguments:ccsize2',mess)
end

% Check high order derivatives
if size(cc,1) >= n
    if any(any(cc(n:end,:)))
        mess = 'Constraints involve derivatives of order %d or larger.';
        error('arguments:difforder',mess,n-1)
    end
    cc = cc(1:n-1,:);
end

% Check exterior constraints
if min(xc) < xlim1 || max(xc) > xlim2
    if periodic
        % Move constraints inside domain
        P = breaks(end) - breaks(1);
        xc = mod(xc-breaks(1),P) + breaks(1);
    else
        mess = 'Some constraints are outside the spline domain.';
        warning('arguments:exteriorconstr',mess)
    end
end

% Pack constraints
constr = struct('xc',xc,'yc',yc,'cc',cc);


%--------------------------------------------------------------------------
function pp = splinebase(breaks,n)
%SPLINEBASE Generate B-spline base PP of order N for breaks BREAKS

breaks = breaks(:);     % Breaks
breaks0 = breaks';      % Initial breaks
h = diff(breaks);       % Spacing
pieces = numel(h);      % Number of pieces
deg = n - 1;            % Polynomial degree

% Extend breaks periodically
if deg > 0
    if deg <= pieces
        hcopy = h;
    else
        hcopy = repmat(h,ceil(deg/pieces),1);
    end
    % to the left
    hl = hcopy(end:-1:end-deg+1);
    bl = breaks(1) - cumsum(hl);
    % and to the right
    hr = hcopy(1:deg);
    br = breaks(end) + cumsum(hr);
    % Add breaks
    breaks = [bl(deg:-1:1); breaks; br];
    h = diff(breaks);
    pieces = numel(h);
end

% Initiate polynomial coefficients
coefs = zeros(n*pieces,n);
coefs(1:n:end,1) = 1;

% Expand h
ii = [1:pieces; ones(deg,pieces)];
ii = cumsum(ii,1);
ii = min(ii,pieces);
H = h(ii(:));

% Recursive generation of B-splines
for k = 2:n
    % Antiderivatives of splines
    for j = 1:k-1
        coefs(:,j) = coefs(:,j).*H/(k-j);
    end
    Q = sum(coefs,2);
    Q = reshape(Q,n,pieces);
    Q = cumsum(Q,1);
    c0 = [zeros(1,pieces); Q(1:deg,:)];
    coefs(:,k) = c0(:);
    % Normalize antiderivatives by max value
    fmax = repmat(Q(n,:),n,1);
    fmax = fmax(:);
    for j = 1:k
        coefs(:,j) = coefs(:,j)./fmax;
    end
    % Diff of adjacent antiderivatives
    coefs(1:end-deg,1:k) = coefs(1:end-deg,1:k) - coefs(n:end,1:k);
    coefs(1:n:end,k) = 0;
end

% Scale coefficients
scale = ones(size(H));
for k = 1:n-1
    scale = scale./H;
    coefs(:,n-k) = scale.*coefs(:,n-k);
end

% Reduce number of pieces
pieces = pieces - 2*deg;

% Sort coefficients by interval number
ii = [n*(1:pieces); deg*ones(deg,pieces)];
ii = cumsum(ii,1);
coefs = coefs(ii(:),:);

% Make piecewise polynomial
pp = mkpp(breaks0,coefs,n);


%--------------------------------------------------------------------------
function B = evalcon(base,constr,periodic)
%EVALCON Evaluate linear constraints

% Unpack structures
breaks = base.breaks;
pieces = base.pieces;
n = base.order;
xc = constr.xc;
cc = constr.cc;

% Bin data
[junk,ibin] = histc(xc,[-inf,breaks(2:end-1),inf]); %#ok

% Evaluate constraints
nx = numel(xc);
B0 = zeros(n,nx);
for k = 1:size(cc,1)
    if any(cc(k,:))
        B0 = B0 + repmat(cc(k,:),n,1).*ppval(base,xc);
    end
    % Differentiate base
    coefs = base.coefs(:,1:n-k);
    for j = 1:n-k-1
        coefs(:,j) = (n-k-j+1)*coefs(:,j);
    end
    base.coefs = coefs;
    base.order = n-k;
end

% Sparse output
ii = [ibin; ones(n-1,nx)];
ii = cumsum(ii,1);
jj = repmat(1:nx,n,1);
if periodic
    ii = mod(ii-1,pieces) + 1;
    B = sparse(ii,jj,B0,pieces,nx);
else
    B = sparse(ii,jj,B0,pieces+n-1,nx);
end


%--------------------------------------------------------------------------
function [Z,u0] = solvecon(B,constr)
%SOLVECON Find a particular solution u0 and null space Z (Z*B = 0)
%         for constraint equation u*B = yc.

yc = constr.yc;
tol = 1000*eps;

% Remove blank rows
ii = any(B,2);
B2 = full(B(ii,:));

% Null space of B2
if isempty(B2)
    Z2 = [];
else
    % QR decomposition with column permutation
    [Q,R,dummy] = qr(B2); %#ok
    R = abs(R);
    jj = all(R < R(1)*tol, 2);
    Z2 = Q(:,jj)';
end

% Sizes
[m,ncon] = size(B);
m2 = size(B2,1);
nz = size(Z2,1);

% Sparse null space of B
Z = sparse(nz+1:nz+m-m2,find(~ii),1,nz+m-m2,m);
Z(1:nz,ii) = Z2;

% Warning rank deficient
if nz + ncon > m2
    mess = 'Rank deficient constraints, rank = %d.';
    warning('solvecon:deficient',mess,m2-nz);
end

% Particular solution
u0 = zeros(size(yc,1),m);
if any(yc(:))
    % Non-homogeneous case
    u0(:,ii) = yc/B2;
    % Check solution
    if norm(u0*B - yc,'fro') > norm(yc,'fro')*tol
        mess = 'Inconsistent constraints. No solution within tolerance.';
        error('solvecon:inconsistent',mess)
    end
end


%--------------------------------------------------------------------------
function u = lsqsolve(A,y,beta)
%LSQSOLVE Solve Min norm(u*A-y)

% Avoid sparse-complex limitations
if issparse(A) && ~isreal(y)
    A = full(A);
end

% Solution
u0 = y/A;

% if size(y,1)==2
%     yy=[y(1,:) y(2,:)];
%     AA=[A;zeros(size(A))]; AA=[AA [zeros(size(A));A]];
%     At=AA';
%     u=lsqrSOL(size(At,1),size(At,2),At,yy',0,0,0,0,100,0)';
%     u=[u(1:length(u)/2);u(length(u)/2+1:end)];
%     sum(sum(abs(u-u0)));
% else
%     u=u0;
% end
u=u0;



% Robust fitting
if beta > 0
    [m,n] = size(y);
    alpha = 0.5*beta/(1-beta)/m;
    for k = 1:3
        % Residual
        r = u*A - y;
        rr = r.*conj(r);
        rrmean = sum(rr,2)/n;
        rrmean(~rrmean) = 1;
        rrhat = (alpha./rrmean)'*rr;
        % Weights
        w = exp(-rrhat);
        spw = spdiags(w',0,n,n);
        % Solve weighted problem
        u = (y*spw)/(A*spw);
    end
end


function u = ladsolve(A,y,insol)
%LSQSOLVE Solve Min |u*A-y|

% Avoid sparse-complex limitations
if issparse(A) && ~isreal(y)
    A = full(A);
end

% initial solution
insol = lsqsolve(A,y,0.5);

% Solution
% options=optimset('Display','off','MaxFunEvals',10,'MaxIter',10);
global ladoptions
[u,fval,exitflag,output] = fminsearch(@(x) l1norm(x,A,y),insol',ladoptions);
u=u';
% fprintf('l1 norm %f\n',l1norm(u',A,y));


function u = ladwcsolve(A,y,breaks,n,pieces,base,dim,xpt)
%LSQSOLVE Solve Min |u*A-y| + int curvature

% initial solution
insol = lsqsolve(A,y,0.5);

% Solution
% options=optimset('Display','off','MaxFunEvals',10,'MaxIter',10);
global ladoptions
[u,fval,exitflag,output] = fminsearch(@(x) l1normwc(x,A,y,breaks,n,pieces,base,dim,xpt),insol',ladoptions);
u=u';


function u = ladwcwssolve(A,y,breaks,n,pieces,base,dim,xpt)
%LSQSOLVE Solve Min |u*A-y| + int curvature + slope

% initial solution
insol = lsqsolve(A,y,0.5);

% Solution
% options=optimset('Display','off','MaxFunEvals',10,'MaxIter',10);
global ladoptions
[u,fval,exitflag,output] = fminsearch(@(x) l1normwcws(x,A,y,breaks,n,pieces,base,dim,xpt),insol',ladoptions);
u=u';

% debugging
% global opt sceneInfo
% utest=insol;
% % size(A)
% % size(utest)
% % size(y)
% resinit=abs(A'*utest'-y');
% resinit=sum(resinit(:));
% 
% % Compute polynomial coefficients
% ii = [repmat(1:pieces,1,n); ones(n-1,n*pieces)];
% ii = cumsum(ii,1);jj = repmat(1:n*pieces,n,1);
% C = sparse(ii,jj,base.coefs,pieces+n-1,n*pieces);
% coefs = utest*C;coefs = reshape(coefs,[],n);
% 
% % Make piecewise polynomial
% pp = mkpp(breaks,coefs,dim);
% spc=getSplineCurvature(pp,xpt)*sceneInfo.frameRate;
% sps=getSplineSlope(pp,xpt)*sceneInfo.frameRate;
% 
% speedpen=sum(-log(1./(spc.^2+1)))*opt.curvatureFactor;
% slopepen=opt.slopeFactor*sum(((sps-1000).^2));
% speedpen=0; slopepen=0;
% 
% finit=opt.unaryFactor*resinit + speedpen + slopepen;
% 
% %%%%%%%%%
% utest=u;
% resend=abs(A'*utest'-y');resend=sum(resend(:));
% 
% % Compute polynomial coefficients
% ii = [repmat(1:pieces,1,n); ones(n-1,n*pieces)];
% ii = cumsum(ii,1);jj = repmat(1:n*pieces,n,1);
% C = sparse(ii,jj,base.coefs,pieces+n-1,n*pieces);
% coefs = utest*C;coefs = reshape(coefs,[],n);
% 
% % Make piecewise polynomial
% pp = mkpp(breaks,coefs,dim);
% spc=getSplineCurvature(pp,xpt)*sceneInfo.frameRate;
% sps=getSplineSlope(pp,xpt)*sceneInfo.frameRate;
% 
% speedpen=sum(-log(1./(spc.^2+1)))*opt.curvatureFactor;
% slopepen=opt.slopeFactor*sum(((sps-1000).^2));
% speedpen=0; slopepen=0;
% fend=opt.unaryFactor*resend + speedpen + slopepen;
% 
% fprintf('init  en: %f\n',finit);
% fprintf('final en: %f, %f\n',fend, fval);




function f = l1norm(x,A,b)
% [size(A') size(x) size(b)]
res=abs(A'*x-b');
f=sum(res(:));

function f = l2norm(x,A,b)
res=(A'*x-b').^2;
f=sum(res(:));

function f = l1normwc(x,A,b,breaks,n,pieces,base,dim,xpt)
global opt
res=abs(A'*x-b');
f=sum(res(:));
u=x';

% Compute polynomial coefficients
ii = [repmat(1:pieces,1,n); ones(n-1,n*pieces)];
ii = cumsum(ii,1);
jj = repmat(1:n*pieces,n,1);
C = sparse(ii,jj,base.coefs,pieces+n-1,n*pieces);
coefs = u*C;
coefs = reshape(coefs,[],n);

% Make piecewise polynomial
pp = mkpp(breaks,coefs,dim);
spc=getSplineCurvature(pp,xpt);

p=opt.curvatureFactor/opt.unaryFactor; % TODO check for div 0
% p*sum(spc)
f=f + p*sum(spc);
% f


function f = l1normwcws(x,A,b,breaks,n,pieces,base,dim,xpt)
global opt sceneInfo

res=abs(A'*x-b');
f=sum(res(:));
u=x';

% Compute polynomial coefficients
ii = [repmat(1:pieces,1,n); ones(n-1,n*pieces)];
ii = cumsum(ii,1);
jj = repmat(1:n*pieces,n,1);
C = sparse(ii,jj,base.coefs,pieces+n-1,n*pieces);
coefs = u*C;
coefs = reshape(coefs,[],n);

% Make piecewise polynomial
pp = mkpp(breaks,coefs,dim);
spc=getSplineCurvature(pp,xpt)*sceneInfo.frameRate;
sps=getSplineSlope(pp,xpt)*sceneInfo.frameRate;

p=opt.curvatureFactor/opt.unaryFactor; % TODO check for div 0
sf=opt.slopeFactor/opt.unaryFactor;
sigA=1/opt.tau;

sigB=opt.tau*sigA;

sigA=0.02; sigB=300*sigA;
sigS=sf;

% sps=sigS*1./(1+exp(-sigA*sps + sigB));

% p*sum(spc)
% f=f + p*sum(spc) + sum(sps);
speedpen=sum(-log(1./(spc.^2+1)))*opt.curvatureFactor;
% speedpen=0;

% slope pen
sp=opt.slopeFactor;
slopepen=sp*sum(((sps-1000).^2));
% slopepen=slopepen+sp*min(((sps-1000).^2));

if ~opt.track3d
    if sceneInfo.scenario==51 || sceneInfo.scenario==53
    ypos=ppval(pp,linspace(xpt(1),xpt(end),length(xpt)));
    ypos=ypos(2,:);
    spc=spc .* ( 1./abs(ypos-200));
    speedpen=sum(-log(1./(spc.^2+1)))*opt.curvatureFactor;
    
    ypos=ppval(pp,xpt); ypos=ypos(2,:);
    slopepen=sp*sum( (sps .* ( 1./abs(ypos-200))).^2);
    end
end
% speedpen=0; slopepen=0;
f=opt.unaryFactor*f + speedpen + slopepen;
% f
% pause
% f
