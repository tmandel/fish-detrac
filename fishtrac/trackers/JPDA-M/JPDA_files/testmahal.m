X = [0.8147 0.9134; 0.9058 0.6324; 0.1270 0.0975]
Y = [0.2785 0.9649; 0.5469 0.1576; 0.9575 0.9706]
D1 = mahal2(X,Y,'mahalanobis', cov(Y))


%https://www.mathworks.com/help/stats/pdist2.html#mw_076526ef-c1e8-4874-927b-db782a554dc9
