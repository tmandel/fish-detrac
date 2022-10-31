function itl = idl2itl(idl,RATIO)

if nargin <2
    RATIO = 3;  % closeness ratio
end
% else nargin == 3 && isempty(RATIO)
%     RATIO = 3;
% end

T = size(idl,2);
D = cell(1,T);
B = cell(1,T);

%% PASS 1) Find associations
t2 = [];
lastminD2 = 0;
for t = 1:T-1
    Nt = size(idl(t).xy,1);
    Ntp1 = size(idl(t+1).xy,1);
    
    % If there are detections for current frame
    if Nt > 0
        B{t} = zeros(Nt,1);
    end
    
    % If there are detections for both current and next frame        
    if Nt > 0 && Ntp1 > 0
        xy1 = idl(t).xy';
        xy2 = idl(t+1).xy';
        
        D{t} = distance_sq(xy1,xy2).^(1/2);
        
        if t==101
            35;
        end

        
        % check first/second ratio        
        [Dsorted,idx] = sort(D{t},2);
        if size(xy2,2)>1
            r = Dsorted(:,2)./Dsorted(:,1);
            f = r>RATIO;
            lastminD2 = min(Dsorted(:,2));
        elseif lastminD2 >0
            % WARNING: Very weird heuristic
            % if there is no double detection to check ratio
            % used the last min second distance
            r = lastminD2./Dsorted(:,1);
            f = r>RATIO;            
%             Ds1(:,1) < MAX_D
        else
            % We do not have any clue about the ratios
            % label them as individual detections
            % following stages will take care of them
            r = 0*Dsorted(:,1);
            f = r>RATIO;            
        end
        
        B{t} = idx(:,1).*f;
        
                
        % check double assignments        
        nu = nonunique(B{t});
        if ~isempty(nu)
            for n=1:length(nu)
                if nu(n)>0
                    B{t}(B{t}==nu(n)) = 0;
                end        
            end
        end
        
        
        
        
        
    end
end
B{T} = zeros(Ntp1,1);

% DEBUG CHECK
for t=1:T
    if length(B{t})~=size(idl(t).xy,1)
        warning('Association Problem');
    end
end

35;

%% PASS 2) Link detections to tracklets
% F = B;  % Processed/Unprocessed Flag
n = 1;
for t=1:T    
      
    for ind=1:size(B{t},1)
        if B{t}(ind) > -1
%     while sum(F{t}>-1) ~= 0
        % get the next tracklet start point (first nonzero index)
%         ind = find(F{t}>-1,1); 
        
        
        
        % get the measurements
        [xy,B] = getxychain(idl,B,t,ind);
        
        % form the itl
        l = size(xy,2);
        itl(n).t_start = t;
        itl(n).t_end = t+l-1;
        itl(n).length = l;
        itl(n).omega = ones(1,l);
        itl(n).data = xy;
        
        n = n+1;
        
        end
    end
end

% DEBUG CHECK
Nidlpts = 0;
for t=1:T
    Nidlpts = Nidlpts + size(idl(t).xy,1);
end
Nitlpts = 0;
for k=1:n-1
    Nitlpts = Nitlpts + itl(k).length;
end

if Nidlpts ~=Nitlpts
    warning('Missing detections in itl formation');
end

35;






%% Utility functions
% bind the detections
function [xy,B] = getxychain(idl,B,t,ind)

T = size(idl,2);
tfirst = t;
xy = zeros(2,T);
% xy = [];


while t <= T && ind>0  %B{t}(ind) ~=0
    
%     xy =[xy idl(t).xy(ind,:)'];
    xy(:,t) = idl(t).xy(ind,:)';
    
    indnext = B{t}(ind);
    B{t}(ind) = -1;
    
    ind = indnext;
    t = t+1;        
end

xy = xy(:,tfirst:t-1);
    
% tlast = tfirst;
% xy(:,tlast) = idl(tlast).xy(ind,:)';
% F{tlast}(ind) = -1;
% 
% 
% while tlast < T && B{tlast}(ind)~=0
%     bind = B{tlast}(ind);
%     
%     xy(:,tlast+1) = idl(tlast+1).xy(bind,:)';
%     F{tlast}(ind) = -1;
%     
%     ind = bind;    
%     tlast = tlast + 1;    
% end
% 
% F{tlast}(bind) = 0;



% delete empty part
% xy = xy(:,tfirst:tlast);


% find repeated numbers in x
function n = nonunique(x)

ux = unique(x);
if length(ux)==1 && length(x)>1
    n = ux;
    return;
end
f = hist(x,ux);
n = ux(f>1);
        

