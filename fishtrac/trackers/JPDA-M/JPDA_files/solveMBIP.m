function [x, fval] = solveMBIP(fE,A,b,Aeq,beq)
try
    disp("Start")
    ctype = 'B';
    disp('A input size')
    disp(size(A))
    disp('b input size')
    disp(size(b))
    %disp('ctype input size')
    %disp(size(ctype))
    %Always look for min
    %options = cplexoptimset();
    %if isFindMax
    %    fE = - fE;
    %end
    %disp("End of ifs")
    constype = []; %TODO: Fill in
    [Ah,numF] = size(A);
    [Aeqh,~] = size(Aeq);
	vartype = repmat('B',numF,1)';
    for i=1:Ah
        constype = [constype;'U'];
    end
    for i=1:Aeqh
        constype = [constype;'S'];
    end
	%disp('vartype size is now')
    %disp(size(vartype))
	disp('consttype is')
    disp(constype)
    %size(A)
    %size(b)
    %disp("End of Fors")
    A = [A;Aeq];
    b = [b;beq];
    size(A)
    param_glpk = struct;
    %options = optimoptions('intlinprog','Display','off','CutGeneration','none','BranchingRule','mostfractional');
    param_glpk.usecuts = 0;
    %disp("end of A");
    %disp(size(vartype));
    %disp(size(constype));
    %                             glpk (c,a,b,lb             ,ub,ctype   ,vartype,sense,param  )
    [x, fval, exitflag, output] = glpk(fE,A,b,zeros(size(fE)),[],constype,vartype,1    ,param_glpk );
    %cplexmilp(f ,Aineq,bineq,Aeq,beq,sostype,sosind,soswt,lb             ,ub,ctype,x0,options)
    %cplexmilp(fE,    A,b    ,Aeq,beq,[]     ,[]    ,[]   ,zeros(size(fE)),[],ctype,x0,options);
    if(exitflag == 210)
		disp('no primal feasible solution');
		x = [];
		v = [];
	end
    disp(exitflag)
    disp(output)
    disp(fval)
    disp(size(x))
catch m
    disp(m.message)
end
