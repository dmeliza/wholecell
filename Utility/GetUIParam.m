function out = GetUIParam(module, param, field)
% Accesses the contents of a GUI object
% out = GetUIParam(module, param, format)
%
%   module - the module in wc
%   param - the tag for the GUI object
%
%   $Id$
global wc

%param = lower(param);
module = lower(module);

% find out if the object exists
sfp = sprintf('isfield(wc.%s.handles,''%s'')',module,param);
if (eval(sfp))
    sf = sprintf('wc.%s.handles.%s', module, param);
    out = get(eval(sf), field);
else
    out = [];
    disp(['no such field ' param ' in module ' module]);
end
    