function printMessage(L,F,varargin)
% print a formatted string as F with values from varargin and debug level L
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.
fprintf(F,varargin{:});
