function out = InitParam(module, param, value)
% Creates a field for a parameter
% 
% OUT = InitParam(MODULE,PARAM,VALUE)
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

sf = sprintf('wc.%s.%s', module, param);
eval(FormatAssignment(sf, value));
