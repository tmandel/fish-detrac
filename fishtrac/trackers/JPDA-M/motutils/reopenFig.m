function h=reopenFig(figname)
% reopen fig of the specified name


% close(findobj('type','figure','name',figname))

h=findobj('type','figure','name',figname);
if isempty(h)
    figure('name',figname);
else
    figure(h);
end
pause(.01);


end