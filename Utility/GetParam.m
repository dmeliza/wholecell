function out = GetParam(module, param)
% Accesses the contents of a GUI object
% out = GetUIParam(module, param)
%
%   module - the module in wc
%   param - the tag for the GUI object
%
%   $Id$
global wc

%param = lower(param);
module = lower(module);

% find out if the object exists
sfp = sprintf('isfield(wc.%s,''%s'')',module,param);
if (eval(sfp))
    sf = sprintf('wc.%s.%s', module, param);
    out = eval(sf);
else
    out = [];
    disp(['no such field ' param ' in module ' module]);
end
    