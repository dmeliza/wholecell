function [x, x_err] = centroid(rf, rf_err)
% Computes the center of mass of a one-parameter receptive field, with
% error estimation.
%
% [X, X_err]    = centroid(RF, [RF_ERR])
%
%
% $Id$
rf  = rf - min(rf);
a   = sum(rf);
b   = sum(rf .* (1:length(rf)));
x   = b/a;
if nargin > 1
    a_e = sqrt(sum(rf_err.^2));
    b_e = sqrt(sum((rf_err .* (1:length(rf))).^2));
    x_e = (a_e/a)^2 + (b_e/b)^2;
    x_err   = sqrt(x_e) * x;
else
    x_err   = 0;
end
    
