function pdfcrop(pdffile)
    eval(sprintf('!pdfcrop %s %s >& /dev/null',pdffile,pdffile));  
end