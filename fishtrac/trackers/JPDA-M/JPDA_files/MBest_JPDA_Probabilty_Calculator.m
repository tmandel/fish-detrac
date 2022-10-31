function F_Pr=MBest_JPDA_Probabilty_Calculator(M,N)

N_T=size(M,1); % Number of targets in the cluster
F_Pr=cell(1,N_T);% Final Probabilities
msp=M{1,1}.Meas_edge(2,end); % number of scans (frames)
Aeq=[]; beq=[]; % Equality constrains for one solution (single route or flow) for each target
f=[];% costs for edges
Edge_inx=zeros(1,N_T); % Accumulator for the number of edges before adding a target
Edge_vec0=cell(1,N_T); % The targets measurements indices to the edges indices in the first scan
for nn=1:N_T
    Aeq=blkdiag(Aeq,M{nn}.A_Eq_Const);
    beq=[beq;M{nn}.b_Eq_Const]; %#ok<*AGROW>
    Edge_inx(nn)=size(f,1);
    f=[f;M{nn}.Costs];
    ind0=find(M{nn}.Meas_edge(2,:)==1);
    Edge_vec0{nn}=Edge_inx(nn)+ind0;
    F_Pr{1,nn}=zeros(size(ind0,2),1);
end

N_E=size(f,1);% Total number of edges
A=[];b=[]; % Inequality constrains to avoid measurement sharing for several targets
if N_T>1
    for ss=1:msp
        T_Meas_Set=[];
        for nn=1:N_T
            T_Meas_Set=[T_Meas_Set M{nn}.Meas_edge(1,M{nn}.Meas_edge(2,:)==ss)];
        end
        T_Meas_Set=unique(T_Meas_Set);
        T_Meas_Set_wo_zero=T_Meas_Set(2:end);
        sizTM=size(T_Meas_Set_wo_zero,2);
        for mm=1: sizTM
            Edge_vec=cell(1,N_T);
            for nn=1:N_T
                ind=find(M{nn}.Meas_edge(2,:)==ss&M{nn}.Meas_edge(1,:)==T_Meas_Set_wo_zero(mm));
                if ~isempty(ind)
                    Edge_vec{nn}=Edge_inx(nn)+ind;
                end
            end
            Edge_vec(cellfun(@isempty,Edge_vec))=[];
            N_T_C=size(Edge_vec,2);
            if N_T_C>1
                Edge_comb=combvec(Edge_vec{:});
                Num_ineq=size(Edge_comb,2);
%                 A0=sparse(zeros(Num_ineq,N_E));
                b0=ones(Num_ineq,1);
                Edge_comb_y = reshape(Edge_comb',1,Num_ineq*N_T_C);
                Edge_comb_x=repmat(1:Num_ineq,[1 N_T_C]);
                A0=sparse(Edge_comb_x,Edge_comb_y,ones(size(Edge_comb_y)),Num_ineq,N_E);
%                 linearInd = sub2ind([Num_ineq N_E], Edge_comb_x, Edge_comb_y);
%                 A0(linearInd)=1;
                A=[A;A0];
                b=[b;b0];
            end
        end
        
    end
end

% Choosing M-best (N Parameter) solutions

% A=sparse(A); 
% Aeq = sparse(Aeq);
%options = optimoptions('intlinprog','Display','off','CutGeneration','none','BranchingRule','mostfractional');
tic
disp('Mbest calling BinIntMBest!')
[candidates, values] = BinIntMBest(f,A,b,Aeq,beq,N);
fprintf('NFramework');
for hc=1:length(values)
    x2 = candidates(:,hc);
    f_prr=exp(-x2'*f);
    
    for nn=1:N_T
     F_Pr{1,nn}(logical(x2(Edge_vec0{nn})),1)=F_Pr{1,nn}(logical(x2(Edge_vec0{nn})),1)+f_prr;
    end
end
toc
% tends = zeros(1,N);
% tic
% hc=1;
% while (hc<=N)
% 
%     % tic
%     [x2,cvalue] = gurobi_ilp(f,A,b,Aeq,beq);%,[],[],[],lb,ub,char('B' * ones(1,N_E)));
%     x2=abs(round(x2));
%     if isempty(x2)
%         %         hold on
%         %         plot(hc,toc,'*r')
%         %         hold off
%         break
%     end
%     f_prr=exp(-x2'*f);
%     A =  [A;x2'];
%     b = [b;N_T*msp-1];
%     tends(hc) = toc;
%     hc=hc+1;
% end
% fprintf('OFramework');
% toc
% hold on
% figure(99);
% plot(tends,'g*');
% hold off;
% xlabel('M');
% ylabel('Running Time');
% legend('Partition-Based Solver', 'Constraint-Based Solver');

F_Pr=cellfun(@(x) x/sum(x), F_Pr, 'UniformOutput', false);



