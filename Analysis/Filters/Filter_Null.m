function out = Filter_Null(action, data, parameters)
% This file defines the stub for the pluggable filters used by
% ProcessResponse.m  The function can be invoked in three
% forms, which are identified by the action parameter.
%
% out = Filter_Null('params',[parameters])
%       Opens a GUI which queries the user for the parameters of the
%       filter.  Returns a parameter structure which can be used to invoke the filter.
% out = Filter_Null('describe',parameters)
%       Returns a string description of the filter's actions (given the parameters)
% out = Filter_Null('view', parameters)
%       Pops up a window with the frequency amplitude and phase response of the filter
%       Or something else if that's more appropriate.
% out = Filter_Null('filter',data, parameter)
%       Filters the data supplied in the second argument given the parameters
%       supplied in the third argument.  If for some reason the parameters are
%       invalid, the function should throw a warning and return the original
%       signal.
%
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    prompt = {'Unused parameter #1'};
    if nargin > 1
        def = {num2str(data.param1)};
    else
        def = {'100'};
    end
    title = 'Values for Null Filter (ignored)';
    answer = inputdlg(prompt,title,1,def);
    if ~isempty(answer)
        out = struct('param1',str2num(answer{1}));
    end
case 'describe'
    out = sprintf('Null Filter (%d)', data.param1);
case 'view'
    figure,freqz(1,1);
case 'filter'
    out = data;
otherwise
    error(['Action ' action ' is not supported.']);
end    