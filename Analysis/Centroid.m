function out = centroid(varargin)
% Computes the center of mass of a one-parameter receptive field.
%
% out    = centroid(RF)
%
% If RF is a single argument, each element is the mean response at each
% position; if it is a list of arguments, then each argument corresponds to
% a position and the elements of the argument correspond to individual
% observations, in which case the centroid and mean will be computed from
% the mean of these observations.
%
% For vector RF, OUT is a single value (the centroid).  For list RFs, OUT
% is a vector with the following values: [centroid; rf(:)]
%
% $Id$

if nargin > 1
    for i = 1:nargin
        rf(i)   = mean(mean(varargin{i}));
    end
else
    rf      = varargin{1};
end

rfa = rf - min(rf);
a   = sum(rfa);
b   = sum(rfa .* (1:length(rfa)));
cm  = b/a;
if nargin > 1
    out = [cm; rf(:)];
else
    out = cm;
end
