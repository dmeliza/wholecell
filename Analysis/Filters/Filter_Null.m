function out = Filter_Null(action, data, parameters)
% This file defines the stub for the pluggable filters used by
% ProcessResponse.m  The function can be invoked in three
% forms, which are identified by the action parameter.
%
% out = Filter_Null('params')
%       Opens a GUI which queries the user for the parameters of the
%       filter.  Returns a parameter structure which can be used to invoke the filter.
% out = Filter_Null('describe',parameters)
%       Returns a string description of the filter's actions (given the parameters)
% out = Filter_Null('filter',data, parameter)
%       Filters the data supplied in the second argument given the parameters
%       supplied in the third argument.
%
% $Id$

switch nargin
case 0
    error('Filter_Null requires at least 1 argument.');
case 1
    prompt = {'Unused parameter #1'};
    def = {'100'};
    title = 'Values for Null Filter (ignored)';
    answer = inputdlg(prompt,title,1,def);
    out.param1 = str2num(answer{1});
case 2
    out = sprintf('Null Filter (%d)', data.param1);
otherwise
    out = data;
end    