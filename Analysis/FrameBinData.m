function out = FrameBinData(data, timing, window)
% Specialized data binning function.  Rather than bins being equally spaced,
% each bin's starting point is defined by a vector of indices.  Bins are the same
% size, however, and this is defined by the window argument, or if this is absent,
% by the mean interval between timing points.
%
% data = FrameBinData(data, timing, [window])
%
% data and timing can be arrays, in which case each column is processed independently
%
% $Id$

error(nargchk(2,3,nargin))

[ldata, ndata] = size(data);
[ltime, ntime] = size(timing);

if ndata ~= ntime
    error('Data and time arrays must have the same number of columns');
end

for i = 1:ndata
    if nargin < 3
        window = mean(diff(timing(:,i)));
    end
    d = frameshift(data(:,i),timing(:,i),window);
    out(:,i) = mean(d,2);
end