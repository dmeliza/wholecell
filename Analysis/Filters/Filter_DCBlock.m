function out = Filter_DCBlock(action, data, parameters)
%
% A specialized highpass filter that removes the DC and extremely low freq components
% b = [1 -1], a = [1 0.95]
%
% parameters:
%   none
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    out = struct('R',0.999);
case 'describe'
    out = sprintf('DC Block');
case 'view'
    % binning is not a LTI filter (or causal), so it's hard to say what to display here
    % what we do is bin some randn data, use xcorr to extract the impulse response
    % function, and display the freqz of an equivalent FIR
    [b,a] = makefilter(data);
    figure,freqz(b,a);
case 'filter'
    if ~isstruct(data)
        out = data;
    else
        for i = 1:length(data)
            [b,a]        = makefilter(parameters);
            data(i).data = filtfilt(b,a,data(i).data);
        end
        out = data;
    end
    
otherwise
    error(['Action ' action ' is not supported.']);
end    

function [b,a] = makefilter(parameters)
b = [1 -1];
a = [1 parameters.R];