function index = CutOutliers(data, time, tolerance)
% Eliminates outliers from a dataset as defined by points which
% are more than (tolerance) standard deviations away from a spline-based
% fit to the data.  Uses some default spline values.
% Returns an index to the points we want to keep.
%
% $Revision$
parameter = 0.1;

[f t] = TimeWeight(data, time, parameter, 1);
err = data - f;
dev = std(err);
index = find(abs(err) <= (tolerance * dev));