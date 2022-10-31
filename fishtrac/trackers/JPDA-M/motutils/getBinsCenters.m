function binc=getBinsCenters(nbins,minval,maxval)
    m=1:2:2*nbins;
    m=m/(2*nbins);
    valran=maxval-minval;
    binc=m*valran+minval;
    
end
