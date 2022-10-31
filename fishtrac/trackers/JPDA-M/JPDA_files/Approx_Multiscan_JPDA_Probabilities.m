function Final_probabilty=Approx_Multiscan_JPDA_Probabilities(M,Obj_info,mbest)

U=size(Obj_info,1);
Final_probabilty=cell(1,U);
%disp('M size')
%disp(size(M))
%reflect lower triangle across diagonal -for undirected graphs
L = tril(M)';
F = tril(M,-1) + L;
M2=sparse(F);
%M2=sparse(M);

%disp('M2 size')
%disp(size(M2))
%[~,C]=graphconncomp(M2, 'Directed','false');
[~,C]=conncomp(M2);
%disp('C size')
%disp(size(C))
C2=C(1:U);
NR=cell2mat(cellfun(@(x) size(x.Prob,1),Obj_info,'UniformOutput', false));

for i=unique(C2)
    ix=(C2==i);
    NR_C=NR(ix);
    if size(NR_C,1)==1
        TNH=NR_C;
    else
        TNH=prod(NR_C);
    end
    %disp('TNH')
    %disp(TNH)
    if TNH<10000||isinf(mbest)
        Final_probabilty(ix)=JPDA_Probabilty_Calculator(Obj_info(ix));
    else
        disp('Approx Multiscan calling mbest');        
        Final_probabilty(ix)=MBest_JPDA_Probabilty_Calculator(Obj_info(ix),mbest);
    end
    
end


