function F_Pr=JPDA_Probabilty_Calculator(M)
N_T=size(M,1); % Number of targets in the cluster

F_Pr=cell(1,N_T);% Final Probabilities
msp=M{1,1}.Meas_edge(2,end); % number of scans (frames)
Hypo_indx=cell2mat(cellfun(@(x) size(x.Prob,1),M,'UniformOutput', false))';

for i=1:N_T
    ind0=find(M{i}.Meas_edge(2,:)==1);
    F_Pr{1,i}=zeros(size(ind0,2),1);
end

if N_T==1
    P_T=prod(M{1}.Prob,2);
    for kk=1:size(ind0,2);
        F_Pr{1,i}(ind0(kk),1)=sum(P_T(M{1}.Hypo(:,1)==M{i}.Meas_edge(1,ind0(kk))));
    end
else
    a= ones(1,N_T);a(N_T)=0;
    temp= zeros(1,N_T);
    temp(N_T)=1;
    
    
    while ~all(a==Hypo_indx)
        
        a= a +temp;
        hypothesis=zeros(msp,N_T);
        for j=N_T:-1:1
            if (a(j)>Hypo_indx(j))
                a(j)= 1;
                a(j-1)= a(j-1)+1;
            end
            
            PT(1,j)=prod(M{j}.Prob(a(j),:));
            hypothesis(:,j)=M{j}.Hypo(a(j),:)';
        end
        chkk=0;
        for jj=1:msp
            zhpo=find(hypothesis(jj,:)==0);
            if (isempty(zhpo)&&length(unique(hypothesis(jj,:)))==N_T)||...
                    (length(unique(hypothesis(jj,:)))==N_T-length(zhpo)+1)
              chkk=chkk+1;  
            else
                break
            end
        end
            
            
        
        if chkk==msp
            for i=1:N_T
                indd=find(M{i}.Meas_edge(2,:)==1&M{i}.Meas_edge(1,:)==M{i}.Hypo(a(i),1));
                F_Pr{1,i}(indd,1)=F_Pr{1,i}(indd,1)+prod(PT);
            end
        end
        
    end
end
F_Pr=cellfun(@(x) x/sum(x), F_Pr, 'UniformOutput', false);



