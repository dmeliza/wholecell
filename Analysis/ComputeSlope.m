function slope = ComputeSlope(trace, baseline, mark, dt)
%
%   Computes the slope between two points on a trace.  However, this method
%   can compute from interval averages or from single points
%   slope = ComputeSlope(trace, baseline, mark, dt)
%     where trace is an MxN array
%     baseline and mark are either scalars or 2x1 vectors (individually)
%     and dt is a scalar.  baseline and mark are in the same time units as dt
%
%   Copyright 2003 Dan Meliza
%   $Id$

% convert units to indices into trace
bs = fix(baseline / dt);
mk = fix(mark / dt);

y1 = mean(trace(bs,:),1);
y2 = mean(trace(mk,:),1);
dx = (mk(length(mk)) - bs(length(bs))) * dt;

slope = (y2 - y1) / dx;