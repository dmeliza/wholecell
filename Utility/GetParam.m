function out = GetParam(module, param)
% Accesses the contents of a non-GUI param
% out = GetParam(module, param)
%
%   module - the module in wc
%   param - the tag for the GUI object
%   out - the param structure (described in OpenParamFigure.m)
%
%   $Id$
global wc

param = lower(param);
module = lower(module);

% find out if the object exists
if ~isfield(wc, module)
    disp(['no such module ' module]);
    return;
end
sfp = sprintf('isfield(wc.%s.param,''%s'')',module,param);
if (eval(sfp))
    sf = sprintf('wc.%s.param.%s', module, param);
    out = eval(sf);
else
    out = [];
    disp(['no such field ' param ' in module ' module]);
end
    