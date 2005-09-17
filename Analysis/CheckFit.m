function [Rsq, P] = CheckFit(X, Y, coefs, model)
%
% CHECKNLFIT calculates goodness-of-fit parameters for a linear or
% nonlinear fit.
%
% [Rsq, P, F] = CheckFit(X, Y, COEFS, MODEL) returns R-squared and P values
% (from an F test) for the fit of the function defined by COEFS and MODEL
% against the X,Y observations. The number of coefficients is used for the
% order of the function. MODEL needs to be a pointer to a function with the
% signature MODEL(COEFS, X);
%
% $Id$

error(nargchk(4,4,nargin))

X       = X(:);
Yp      = feval(model, coefs, X);
resid   = Y - Yp;
SSE     = sum(power(resid,2));
SST     = sum(power(Y - mean(Y),2));
Rsq     = 1 - SSE/SST;

if nargout > 1
    dfr     = length(coefs);
    dfe     = length(X) - 1 - dfr;
    MSE     = SSE/dfe;
    MSR     = (SST-SSE)/dfr;

    F       = MSR/MSE;
    P       = 1 - fcdf(F,dfr,dfe);
end
