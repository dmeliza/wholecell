function out = InitParam(module, param, struct)
% Creates fields in wc so that subsequent get and set commands
% work for this parameter
% 
% OUT = InitParam(MODULE,PARAM,struct)
% 		Sets the param to struct (described in OpenParamFigure.m)
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

sf = sprintf('wc.%s.param.%s = struct;', module, param);
eval(sf);
out = GetParam(module, param);
