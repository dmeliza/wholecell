function [time,data] = TimeBin(time, data, bins, option)
%
% Rebins data into new timing vector.
%
% [TIME,DATA] = TIMEBIN(time, data, binwidth) uses a fixed binwidth
% (units are those of the time vector).  Bins with more than one
% data point are represented by the mean, while bins with no data
% points are dropped from the output vector.  Note that the bins generated
% begin on the first integer multiple of the binsize (which comes in useful
% when comparing multiple datasets as this synchronizes the data)
%
% [TIME,DATA] = TIMEBIN(time, data, bins), where BINS is a vector of
% length greater than 1, rebins the data into the vector.  Invalid and
% empty time points are dropped.
%
% [TIME,DATA] = TIMEBIN(...,'interp') uses the INTERP1 function to perform
% the operation.  Note that this tends to follow the input curve quite closely,
% especially if time bins line up with input time values.
%
% $Id$

error(nargchk(3,4,nargin))

nbin    = length(bins);
if nbin == 1
    mn  = min(time);
    mn  = mn - mod(mn,bins);
    XI  = mn:bins:max(time);
else
    XI  = bins(bins<=max(time));
end
nbin    = length(XI);

if nargin == 3
    XI  = [XI Inf];
    YI  = zeros(1,nbin);
    S   = warning('off');
    for i = 1:nbin
        ind     = time >= XI(i) & time < XI(i+1);
        YI(i)   = mean(data(ind));      % gives NaN for empty ind
    end
    warning(S);
elseif strcmpi(option,'interp')
    YI = interp1(time, data, XI,'cubic');
end
% clean up output
ind     = ~isnan(YI);
time    = XI(ind)';
data    = YI(ind)';
    