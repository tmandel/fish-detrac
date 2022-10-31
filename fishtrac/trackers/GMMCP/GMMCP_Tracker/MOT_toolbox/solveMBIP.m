function x = solveMBIP(fE,A,b,Aeq,beq,ctype,x0,isFindMax)
try
    %disp("Start")
    %disp('A input size')
    %disp(size(A))
    %disp('b input size')
    %disp(size(b))
    %disp('ctype input size')
    %disp(size(ctype))
    %options = cplexoptimset();
    %options = cplexoptimset();
    if isFindMax
        fE = - fE;
    end
    disp("End of ifs")
    vartype = ctype;
    constype = []; %TODO: Fill in
    for i=1:size(A)
        constype = [constype;'U'];
    end
    for i=1:size(Aeq)
        constype = [constype;'S'];
    end
    %disp('consttype size')
    %disp(size(constype))
    %options = cplexoptimset();
    %size(A)
    %disp("End of Fors")
    A = [A;Aeq];
    b = [b;beq];
    size(A)
    param = struct;
    %disp("end of A")
    %                             glpk (c,a,b,lb             ,ub,ctype   ,vartype,sense,param  )
    [x, fval, exitflag, output] = glpk(fE,A,b,zeros(size(fE)),[],constype,vartype,1    ,param);
    %cplexmilp(f ,Aineq,bineq,Aeq,beq,sostype,sosind,soswt,lb             ,ub,ctype,x0,options)
    %cplexmilp(fE,    A,b    ,Aeq,beq,[]     ,[]    ,[]   ,zeros(size(fE)),[],ctype,x0,options);
    
    disp(exitflag)
    disp(output)
    disp(fval)
    disp(x)
catch m
    disp(m.message)
end
