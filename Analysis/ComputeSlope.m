function slope = ComputeSlope(trace, time, baseline, mark)
%
%   Computes the slope between two points on a trace.  However, this method
%   can compute from interval averages or from single points
%   slope = ComputeSlope(trace, baseline, mark, dt)
%     where trace is an MxN array
%     baseline and mark are either scalars or 2x1 vectors (individually)
%     and dt is a scalar.  baseline and mark are in the same time units as dt
%
%   traces are computed columnwise (ie t runs in dim 2)
%   Copyright 2003 Dan Meliza
%   $Id$

% convert units to indices into trace
dt = time(2) - time(1);
bs = fix((baseline - time(1))/ dt) + 1;
mk = fix((mark - time(1))/ dt) + 1;

y1 = mean(trace(:,bs),2);
y2 = mean(trace(:,mk),2);
dx = (mk(length(mk)) - bs(length(bs))) * dt;

slope = (y2 - y1) / dx;