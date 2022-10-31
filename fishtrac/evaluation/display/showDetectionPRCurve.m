function AP = showDetectionPRCurve(detprFile, detectorName)

global options

% load the PR file
disp(detprFile);
detResult = load(detprFile);
disp(detResult);
rec = detResult(:,1);
prec = detResult(:,2);
AP = roundn(VOCap(rec,prec)*100,-2);

if(options.showDetectionCurve)
    fontSizeLegend = 14;
    fontSize = 14;
    curFig = figure(1);
    curAxes = axes('Parent',curFig,'FontSize',14);    
    if(numel(rec)<100)
        legendName = detectorName;            
    else
        legendName = [detectorName ' (' num2str(roundn(AP,-2)) '%)'];  
    end
    plot(detResult(:,1),detResult(:,2),'color','r','lineStyle','-','lineWidth',5,'Parent',curAxes);grid on;hold on;   
    title(['Detection Curve of ' detectorName],'fontsize',fontSize);
    xlabel('Recall','fontsize',fontSize);
    ylabel('Precision','fontsize',fontSize);
    axis([0 1 0 1]);
    legend(legendName,'Interpreter','none','fontsize',fontSizeLegend,'Location','SouthEast');
end