function printMetrics(metrics, metricsInfo, dispHeader,dispMetrics,padChar)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

namesToDisplay=metricsInfo.names.long;
widthsToDisplay=metricsInfo.widths.long;
formatToDisplay=metricsInfo.format.long;

namesToDisplay=metricsInfo.names.short;
widthsToDisplay=metricsInfo.widths.short;
formatToDisplay=metricsInfo.format.short;

if nargin<3, dispHeader=1; end
if nargin<4
    dispMetrics=1:length(metrics);
end
if nargin<5
    padChar={' ',' ','|',' ',' ',' ','|',' ',' ',' ','| ',' ',' ',' '};
end

if dispHeader
    for m=dispMetrics
        printString=sprintf('fprintf(''%%%is%s'',char(namesToDisplay(m)))',widthsToDisplay(m),char(padChar(m)));
        eval(printString)
    end
    fprintf('\n');
end

for m=dispMetrics
    printString=sprintf('fprintf(''%%%i%s%s'',metrics(m))',widthsToDisplay(m),char(formatToDisplay(m)),char(padChar(m)));
    eval(printString)
end

% if standard, new line
if nargin<4
    fprintf('\n');
end