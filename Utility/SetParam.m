function out = SetParam(module, param, value)
% Sets parameters of a module
% 
% OUT = SETUIPARAM(MODULE,PARAM,VALUE)
% 		Sets the param to VALUE
%       returns the actual value
% 	
%
% adapted from exper, ZF MAINEN, CSHL, 8/00
%
% $Id$
global wc

param = lower(param);
module = lower(module);
out = [];

% find out if the object exists
sfp = sprintf('isfield(wc.%s.param,''%s'')',module,param);
if (eval(sfp))
    sf = sprintf('wc.%s.param.%s.value', module, param);
    eval(FormatAssignment(sf, value));
    out = GetParam(module, param);
else
    disp(['no such field ' param ' in module ' module]);
end