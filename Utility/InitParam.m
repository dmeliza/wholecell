function out = InitParam(module, param, struct)
% Creates fields in wc so that subsequent get and set commands
% work for this parameter.
% 
% OUT = InitParam(module,param,struct)
%
% module - the module to which this parameter pertains
% param  - the name of the parameter
% struct - the param structure
%
% returns the param structure as stored in the wc structure
%
% See Also:
%  	headers/param_struct.m  - defines the param structure that should be used
%
% adapted from exper, ZF MAINEN, CSHL, 8/00
%
% $Id$
global wc

param = lower(param);
module = lower(module);
out = [];

sf = sprintf('wc.%s.param.%s = struct;', module, param);
eval(sf);
out = GetParam(module, param);
