function [ x, xv ] = BinIntMBest( f,A,b,Aeq,beq, M )
%INTMBEST Summary of this function goes here
%   Detailed explanation goes here
disp('calling binintmbest!')
willplot = 0;
xdim = length(f);
x = zeros(xdim, M);
y = zeros(xdim, M);
xv = zeros(M,1);
yv = zeros(M,1);
Constraints = cell(M,1);
if(willplot)
    tstart = tic;
    tends=zeros(1,M);
end
for m=1:M
    if(m==1)
	  disp('calling gurobi!')
      [cx, value] = solveMBIP(f, A,b,Aeq,beq);
	  disp("solution returned was")
      disp(cx)
      cx = abs(round(cx));
      x(:,m) = cx;
      xv(m) = value;
    else
        [c, k] = min(yv(1:(m-1)));
        if(c == 1e20)
            m = m - 1;
            break;
        end
        x(:,m) = y(:,k);
        xv(m) = yv(k);
        diff1 = (x(:,m) ~= x(:,k));
		disp("trying to find a 1 in")
		disp(diff1)
		disp(cy)
        diff = find(diff1==1);
        Constraints{m} = [Constraints{k}; diff(1), x(diff(1), m)];
        Constraints{k} = [Constraints{k}; diff(1), ~x(diff(1), m)];
        [value,cy] = CalcNextBestSolution(Constraints{k}, x(:,k),f, A, b, Aeq, beq);
        cy = abs(round(cy));
        y(:,k) = cy;
        yv(k) = value;
    end
    [value, cy] =  CalcNextBestSolution(Constraints{m}, x(:,m), f, A, b, Aeq, beq);
    cy = abs(round(cy));
    y(:,m) = cy;
    yv(m) = value;
    if(willplot)
        tends(m) = toc;
    end
end
M = m;
xv = xv(1:M);
x=x(:,1:M);
if(willplot)
    
    figure(99);
    plot(1:M,tends,'r+');
end
end

function [v,y] = CalcNextBestSolution(ce, xstar,f, A,b,Aeq,beq)
xdim = length(xstar);
A=[A;xstar'];
b=[b;sum(xstar) - 1];
[ch, ~] = size(ce);
y = zeros(xdim, 1);
assigned = zeros(xdim, 1); 
v = 0;
if(~isempty(ce))
    y(ce(:,1)) = ce(:,2);
    assigned(ce(:,1)) = 1;
    
    b = b - A * y;
    beq = beq - Aeq * y;
    v = f' * y;
    
    f(ce(:,1)) = [];
    A(:,ce(:,1)) = [];
    Aeq(:,ce(:,1)) = [];
end
disp("calling gurobi lower down!")
[y1, v1] = solveMBIP(f, A, b, Aeq, beq);
disp("solution returned was")
disp(y1)
y1=abs(round(y1));
if(isempty(y1))
    v = 1e20;
else
    y(assigned == 0) = y1;
    v = v + v1;
end
end


