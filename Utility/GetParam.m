function out = GetParam(module, param, varargin)
% Accesses the contents of a non-GUI param
% out = GetParam(module, param, ['value'])
%
%   module - the module in wc
%   [param - the tag for the GUI object] (if not supplied, all params are returned)
%   'value' - if supplied, only the value is returned
%   out - the param structure (described in OpenParamFigure.m)
%
%   $Id$
global wc

module = lower(module);
out = [];

% find out if the object exists
if ~isfield(wc, module)
    %disp(['no such module ' module]);
    return;
end
if nargin == 1
    sf = sprintf('wc.%s.param', module);
    out = eval(sf);
else
    param = lower(param);
    sfp = sprintf('isfield(wc.%s.param,''%s'')',module,param);
    if (eval(sfp))
        sf = sprintf('wc.%s.param.%s', module, param);
        out = eval(sf);
    else
        %disp(['no such field ' param ' in module ' module]);
    end
    
    if nargin > 2
        out = GetPValue(out);
    end
end

