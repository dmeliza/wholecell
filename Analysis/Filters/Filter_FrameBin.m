function out = Filter_FrameBin(action, data, parameters)
%
% Downsamples data by binning it according the boundaries given
% in the timing vector.  At present we use a rectangular window
% whose width is given by the average time between frame beginnings.
%
% parameters:
%   none
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    out    = struct('param1','ignore');
case 'describe'
    out = sprintf('Frame Binning Filter');
case 'view'
    % there's no way to predict the output of this filter without
    % knowing the timing data, so this action does nothing
case 'filter'
    if ~isstruct(data)
        out = data;
    else
        for i = 1:length(data)
            Fs      = data(i).t_rate;                   % samples / sec
            br      = mean(diff(data(i).timing));       % samples / frame
            data(i).data    = FrameBinData(data(i).data,data(i).timing);
            data(i).t_rate  = fix(Fs/br);               % frames / sec
            data(i).timing  = [1:length(data(i).data)]';   % each sample is a frame
        end
        out = data;
    end
    
otherwise
    error(['Action ' action ' is not supported.']);
end    