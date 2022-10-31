function [Final_probabilty,MaxNumHypo]=JPDA_Probabilities(M,Obj_indx,Obj_probabilty)   
U=size(Obj_indx,2);
Final_probabilty=cell(1,U);
MaxNumHypo=zeros(U,1);
M2=sparse(M);
[~,C]=graphconncomp(M2,'Directed','false');
C2=C(1:U);
if length(unique(C2))==U
    Final_probabilty=cellfun(@(x) x/sum(x), Obj_probabilty, 'UniformOutput', false);
else   
    for i=unique(C2)
        if length(C2(C2==i))==1
            Final_probabilty((C2==i))=cellfun(@(x) x/sum(x), Obj_probabilty(C2==i), 'UniformOutput', false);
        else
        [Final_probabilty((C2==i)),MaxNumHypo((C2==i))]=JPDA_Probabilty_Generator(Obj_indx((C2==i)),Obj_probabilty((C2==i)));
        end
    end
end
