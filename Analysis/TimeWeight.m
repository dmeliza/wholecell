function [f, t] = TimeWeight(data, time, parameter, resolution)
% uses the spline toolkit to generate a smoothed timeweighted average
% of the data.
% parameter - the parameter for csaps (0.1 works nicely)
% resolution - the amount of interpolation (e.g. 100)
%
% Copyright Dan Meliza 2003
% $Revision$
f = [];
t = [];

if (length(time) ~= length(data))
    return;
elseif (length(time) < 2)
    return;
end

if resolution==1
    t = time;
else
    len = max(time) - min(time);
    t = time(1):len/resolution:time(1)+len;
end
spline = csaps(time, data, parameter, []);
f = fnval(spline,t);