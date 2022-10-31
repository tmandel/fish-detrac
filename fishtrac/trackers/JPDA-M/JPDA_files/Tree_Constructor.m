function [TMindx,TMprob,X_E,Sigma_E,S_E,K_E,optimiz]=Tree_Constructor(X,Sigma,F,Q,H,R,Z,S_l,d_G,pD,Beta,M)

msp=size(Z,2);
X_p=X;
Sigma_p=Sigma;

TMindx=cell(1,msp);
TMprob=cell(1,msp);
X_u=[];
ssD=zeros(1,msp);

for i=1:msp
    
    X_e=F*X_p;
    SizD=size(Sigma_p,3);
    TMindx{i}=cell(SizD,1);
    TMprob{i}=cell(SizD,1);
    SM=0;
    if i>1
        ssD(1,i)=SizD;
        Edge_ind2=sum(ssD(1,1:i));
        Edge_ind=sum(ssD(1,1:i-1));
    end
    
    for j=1:SizD
        Sigma_e=Q+F*Sigma_p(:,:,j)*F';
        S=H*Sigma_e*H'+R;
        K=Sigma_e*H'/S;
        if i==1
            X_E=X_e;
            Sigma_E=Sigma_e;
            S_E=S;
            K_E=K;
        end
        if max(max(S))>S_l %limit S matrix
            S_G=S*S_l/max(max(S));
        else
            S_G=S;
        end
        S_G=(S_G+S_G')*0.5;
        
        if isempty(Z{1,i})
            TMindx{i}{j}=[];
        else
            [dis, inx]= sort(mahal2(Z{1,i} ,(H*X_e(:,j))','mahalanobis',S_G));
            
            TMindx{i}{j}=inx(dis<d_G);
        end
        GMeaur=Z{1,i}(TMindx{i}{j},:);
        sizM= size(GMeaur,1);
        
        if isempty(TMindx{i}{j})
            TMprob{i}{j}=(1-pD)*Beta;
        else
            DS=dis(dis<d_G);
            gij=exp(-(DS.^2)/2)/(((2*pi)^(M/2))*det(S)^0.5);
            TMprob{i}{j}=[(1-pD)*Beta;...
                gij*pD];
        end
        if i==1
            optimiz.Meas_edge=[0 TMindx{i}{j}';i*ones(1,sizM+1)];
            optimiz.Hypo=zeros(sizM+1,msp);
            optimiz.Prob=zeros(sizM+1,msp);
            optimiz.Hypo(:,i)=[0;TMindx{i}{j}];
            optimiz.Prob(:,i)=TMprob{i}{j};
            optimiz.A_Eq_Const=sparse(ones(1,sizM+1));
            optimiz.b_Eq_Const=1;
            optimiz.Costs=-log(TMprob{i}{j});
            %             Routes(:,1)=(0:sizM)';
            %             Measur_indx(:,1)=[0;TMindx{i}{j}];
            %             Cost_prob(:,1)=TMprob{i}{j};
        else
            if j==1
                Hypo2=optimiz.Hypo;
                Prob2=optimiz.Prob;
                optimiz.Hypo=[];
                optimiz.Prob=[];
            end
            optimiz.Costs=[optimiz.Costs;-log(TMprob{i}{j})];
            optimiz.Meas_edge=[optimiz.Meas_edge [0 TMindx{i}{j}';i*ones(1,sizM+1)]];
            hypoo=repmat(Hypo2(j,:),[sizM+1,1]);
            probo=repmat(Prob2(j,:),[sizM+1,1]);
            hypoo(:,i)=[0;TMindx{i}{j}];
            probo(:,i)=TMprob{i}{j};
            optimiz.Hypo=[optimiz.Hypo;hypoo];
            optimiz.Prob=[optimiz.Prob;probo];
            SM=SM+sizM+1;
            node_flow=zeros(1,Edge_ind2+SM);
            node_flow(1,Edge_ind+j)=-1;
            node_flow(1,end-(sizM):end)=ones(1,sizM+1);
            optimiz.A_Eq_Const=[optimiz.A_Eq_Const zeros(size(optimiz.A_Eq_Const,1),sizM+1); node_flow];
            optimiz.b_Eq_Const=[optimiz.b_Eq_Const;0];
            %             if j==1
            %                 Routes=[repmat(Routes_t(j,1:i-1),[sizM+1,1]) (0:sizM)'];
            %                 Measur_indx=[repmat(Measur_indx_t(j,1:i-1),[sizM+1,1]) [0;TMindx{i}{j}]];
            %                 Cost_prob=[repmat(Cost_prob_t(j,1:i-1),[sizM+1,1]) TMprob{i}{j}];
            %             else
            %                 Routes(end+1:end+sizM+1,:)=[repmat(Routes_t(j,1:i-1),[sizM+1,1]) (0:sizM)'];
            %                 Measur_indx(end+1:end+sizM+1,:)=[repmat(Measur_indx_t(j,1:i-1),[sizM+1,1]) [0;TMindx{i}{j}]];
            %                 Cost_prob(end+1:end+sizM+1,:)=[repmat(Cost_prob_t(j,1:i-1),[sizM+1,1]) TMprob{i}{j}];
            %             end
        end
        if i~=msp
            if isempty(GMeaur)
                Y_u=[];
            else
                Y_u=GMeaur'-repmat((H*X_e(:,j)),[1,sizM]);
            end
            if j==1
                X_u(:,1)=X_e(:,j);
                Sigma_u(:,:,1)=Sigma_e;
            else
                X_u(:,end+1)=X_e(:,j); %#ok<*AGROW>
                Sigma_u(:,:,end+1)=Sigma_e;
            end
            if ~isempty(GMeaur)
            X_u(:,end+1:end+sizM)=repmat(X_e(:,j),[1,sizM])+K*Y_u;
            end
            Sigma_u(:,:,end+1:end+sizM)=repmat(Sigma_e-K*H*Sigma_e,[1,1,sizM]);
        end
    end
    if i~=msp
        X_p=X_u;
        Sigma_p=Sigma_u;
        clear X_u Sigma_u
    end
    
end
