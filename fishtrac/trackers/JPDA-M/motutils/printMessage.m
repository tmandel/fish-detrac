function printMessage(L,F,varargin)
% print a formatted string as F with values from varargin and debug level L


global opt

if ~isfield(opt,'verbosity'), opt.verbosity=3; end

if L<=opt.verbosity
    fprintf(F,varargin{:});
end
end