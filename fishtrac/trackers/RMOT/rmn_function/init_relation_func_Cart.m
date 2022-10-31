function [Var] = init_relation_func_Cart(s1,s2)


diff_s = s1-s2;
TransX = diff_s(1);
TransY = diff_s(2);
Var.X = [TransX TransY 0 0]';
Var.P = [2 0 0 0;0 2 0 0;0 0 2 0;0 0 0 2].^2;

