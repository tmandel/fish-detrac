function drawitl3D(itl,dims)

% user may pick two dimensions to plot over time. if it is not input
% the default will be first two dimensions.
if nargin <2
    dims = (1:2);
else
    if length(dims)~=2
        error('number of selected plot dimensions must be 2!');
    end
end


N_itl = size(itl,2);

for n=1:N_itl
    
    
    t  = (itl(n).t_start:1:itl(n).t_end); 
    xy = itl(n).data(dims,:);

    
    
    omega = itl(n).omega;
    xy1 = xy;
    xy0 = xy;
    t1 = t;
    t0 = t;
    
    % the following is to avoid choppy trajectories
    % and keep the continuity with inpainting
    % the inpainted parts will be shown in red
    domega = conv(omega,[1 1 1],'same');
    xy1(:,domega==0) = nan;
    t1(domega==0) = nan;    
    xy0(:,omega==1) = nan;    
    t0(omega==1) = nan;
    
    % plot
    plot3(t1,xy1(1,:),xy1(2,:),'b-',...
         t0,xy0(1,:),xy0(2,:),'r-x'); hold on;


%     text(itl(n).t_start,itl(n).xy_start(dim),int2str(n));
end

xlabel('time');
ylabel(['dimension ' num2str(dims(1))]);
zlabel(['dimension ' num2str(dims(2))]);

hold off;
grid on;
