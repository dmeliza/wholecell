function out = SetUIParam(module, param, field, value)
% Sets parameters of a GUI object in a module
% 
% OUT = SETUIPARAM(MODULE,PARAM,VALUE)
% 		Sets the field 'value' to VALUE
%       returns the actual value
%       field and value can be cell arrays
% 	
%
% adapted from exper, ZF MAINEN, CSHL, 8/00
%
% $Id$
global wc

%param = lower(param);
module = lower(module);
out = [];

% find out if the object exists
if (isfield(wc, module))
    sfp = sprintf('isfield(wc.%s.handles,''%s'')',module,param);
    if (eval(sfp))
        sf = sprintf('wc.%s.handles.%s', module, param);
        set(eval(sf), field, value);
        out = get(eval(sf), field);
    else
        %disp(['no such field ' param ' in module ' module]);
    end
else
    %disp(['module ' module ' has not been loaded']);
end
    