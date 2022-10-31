function [x,v] = gurobi_ilp(f, A, b, Aeq, beq)
%TODO:" Optimoptions?
try
    clear model;
    model.obj = f;
    model.A = sparse([A;Aeq]);
    model.rhs = [b;beq];
    [Ah,~] = size(A);
    [Aeqh,~] = size(Aeq);
    model.sense = char(['<' * ones(1, Ah), '=' * ones(1,Aeqh)]);
    model.vtype = 'B';
    model.modelsense = 'min';
    clear params;
    params.outputflag = 0;
    result = gurobi(model, params);
    x = result.x;
    v = result.objval;
catch gurobiError
    x = [];
    v = [];
end
end

