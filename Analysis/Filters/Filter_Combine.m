function out = Filter_Combine(action, data, parameters)
%
% Combines multiple repeats into a single r1 structure.
%
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    out = struct('param1','ignored');
case 'describe'
    out = sprintf('Combine Signals');
case 'view'
    % averaging is not a SISO filter, and the frequency response should be flat
    % for pure white noise
case 'filter'
    if ~isstruct(data)
        out = data;
    else
        d = struct2array(data,'data','clip');     % combine into array, dropping extra samples
        d = mean(d,2);
        data = data(1);
        data.data = d;
        out = data;
    end
    
otherwise
    error(['Action ' action ' is not supported.']);
end    