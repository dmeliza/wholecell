function [x, x_err] = centroid(rf, rf_err)
% Computes the center of mass of a one-parameter receptive field, with
% error estimation.
%
% [X, X_err]    = centroid(RF, [RF_ERR])
%
% The error can be calculated by propagation of error, in which case a mean
% and standard error need to be supplied for each point in the RF.  Or a
% nonparameteric bootstrap can be used, in which case RF should be a cell
% array with the measured values for each data point.
%
%
% $Id$



if iscell(rf)
%    fun     = @my_centroid;
    fun     = @test;
    NBOOT   = 100;
    cm      = bootstrp(NBOOT,fun,rf{1});
    keyboard
else        
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
end

function [cm] = my_centroid(X)
% actually computes the centroid from an n-sample set
    

function [cm] = bs_centroid(varargin)
% bootstrappable function for computing the centroid
d   = [varargin{:}];
a   = sum(d);
b   = sum(d .* 1:length(d));
cm  = b/a;
