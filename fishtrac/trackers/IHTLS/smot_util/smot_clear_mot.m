function mot = smot_clear_mot(itl0,itlh,intthresh)

% itl0: original (ground truth) tracklet labels
% itlh: hypothesis tracklet labels
% intthresh: intersection threshold
Nmax = size(itl0,2);
M = zeros(Nmax,1);    % correspondence list for original
% NHmax = size(itlh,2);
% H = zeros(NHmax,1);     % correspondence list for hypothesis
T_end = max([itl0.t_end]);

% FIX: the hypothesis tracklets do not have id field
for n=1:size(itlh,2)
    itlh(n).id = n; 
end

% FIX: start ground truth id's from 1.
for n=1:size(itl0,2)
    itl0(n).id = n;
end

% WARNING: Use below with caution. It may be completely wrong.
% FIX: make inpaintings part of tracklets to avoid wrong false negatives
for n=1:size(itlh,2)
    itlh(n).omega = ones(size(itlh(n).omega));
end


mme = 0;fp = 0;fn = 0;
g = 0;
for t = 1:T_end
   
    % Ground truth has rectangles of detections
    [oidx,oxy,orects] = getitlxywh(itl0,t);
    % Hypothesis only have xy
    [hidx,hxy,hrects] = getitlxywh(itlh,t);
    
    No = size(oidx,2);
    Nh = size(hidx,2);
    
    
    % find correspondences
    if Nh > 0 && No >0  % if they are not both empty        
        W_mean = mean(orects(3,:));
        th = intthresh *W_mean; %threshold        
        c = find_correspondences(oxy,hxy,th);
    else
        c = zeros(1,No);
    end
    
        
    
    Na = sum(c>0); % number of assigned
    % if there are more hypothesis than assigned they are false positive
    fp = fp + (Nh - Na);
    
    if(Nh-Na) >0
        35;
    end
    
    % if there are objects which could not be assigned they are false
    % negative (misses)
    if No > Na
        35;
    end
    fn = fn + (No - Na);
    
    if 0 & (No-Na)>0
        figure(51);clf;
        for i=1:size(orects,2)
            rectangle('Position',orects(:,i),'EdgeColor','r');
        end
        figure(52);clf;
        for i=1:size(hrects,2)
            rectangle('Position',hrects(:,i),'EdgeColor','b');
        end
        
        
        35;
    end
    
    % correspondences for this time spot
%     [oidx' hidx(c)']   % debug


    
    for n = 1:size(oidx,2)
        
        if c(n) > 0 
            if M(oidx(n)) == 0  &&  sum(M==hidx(c(n))) == 0 % first assignment
                M(oidx(n)) =  hidx(c(n));                
            elseif M(oidx(n)) ~=  hidx(c(n))    % mismatch (label changed)
                % clear other assignments
                M(M==hidx(c(n))) = 0;
                % update with new assignment
                M(oidx(n)) =  hidx(c(n));
                mme = mme + 1;
            end                
        end
        
        % check for switches        
%         if ((t == itl0(oidx(n)).t_start) || (M(oidx(n)) == 0)) && c(n)>0
%            M(oidx(n)) =  hidx(c(n));
%         elseif c(n)>0
%             if M(oidx(n)) ==  hidx(c(n))
%             else
%                 M(oidx(n)) =  hidx(c(n));
%                 mme = mme + 1;
%             end
%         end
    end

    
    g = g + No;
end
% ATTENTION: we did not compute false positives.
mota = 1 - (mme+fn+fp)/g;
mmerat = 1 - mme/g;
% fprintf(' mme:%g\n fn:%g\n fp:%g\n mota:%g\n mmeratio:%g\n ',mme,fn,fp,mota,mmerat);
fprintf('mme:%3g\tfn:%3g\tfp:%3g\tmota:%0.4f\n',mme,fn,fp,mota);


mot.fn = fn;
mot.fp = fp;
mot.mme = mme;
mot.g = g;
mot.mota = mota;
mot.mmerat = mmerat;

35;









function tidx = itl_tidx(itl)
T = max([itl.t_end]);
tidx = cell(1,T);
for i=1:size(itl,2)
    for t = itl(i).t_start:itl(i).t_end
        tidx{t} = [tidx{t} i];
    end
end

function c = find_correspondences(oxy,hxy,th)

% oxy   : ground truth xy
% hxy   : hypothesis xy

% find the correspondences
D = distance_sq(oxy,hxy).^(1/2);

% we want detections within a radius
D(D>th) = 1e8;  % munkres does not like inf
c = munkres(D);
