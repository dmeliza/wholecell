function [coefs, expr, Rsq, P, ci] = ExpDecayFit(X, Y, ALPHA)
%
% SINGLEEXPFIT: fits a single exponential decay to data
%
% [coefs, expr, Rsq] = ExpDecayFit(X, Y) returns the coefficients
% for the exponential function defined by: Y = b(1) * exp(-abs(X)/b(2)),
% where b(1) and b(2) are the coefficients of the fit. X must be a vector;
% Y must have the same number of rows as X. If Y has multiple columns the
% fit is calculated from the row means.
%
% [coefs, expr, Rsq, P, ci] = ExpDecayFit(X, Y, [ALPHA]) also finds the P 
% value for the goodness of fit (F test against mean) and the confidence 
% intervals of the coefficients. If ALPHA is not set it defaults to 0.05
%
% Note that this function cannot be used to fit functions with an additive
% parameter (ie Y = b(0) + b(1) * exp(-abs(X)/b(2))). If the value of b(0)
% is known, however, it can be subtracted from Y prior to running this
% function.
%
% $Id$

error(nargchk(2,3,nargin))
if nargin < 3
    ALPHA = 0.05;
end

% Set up the fit function
expr    = 'b(1) * exp(-abs(x)/b(2))';
fun     = inline(expr,'b','x');

% Condition the data
X       = X(:);
Y       = mean(Y,2);
if ~isequal(size(X),size(Y))
    error('wholecell:SingleExpFit:XYSizeMismatch',...
          'X and Y vectors must be the same size.')
end

% Guess likely values for the parameters. 
% b(1) is the y-intercept:
[mn,i]      = min(abs(X));
b(1)        = Y(i);
% b(2) is the X value closest to b(1)/exp(1)
[mn,i]      = min(abs(Y - b(1)/exp(1)));
b(2)        = abs(X(i));    % 

% run the fit
[coefs,resid,J]   = nlinfit(X, Y, fun, b);

% only run the statistical tests the user asks for; this makes the function
% faster to bootstrap
if nargout > 2
    SSE     = sum(power(resid,2));
    SST     = sum(power(Y - mean(Y),2));
    Rsq     = 1 - SSE/SST;
end
if nargout > 3
    dfr     = length(coefs);
    dfe     = length(X) - 1 - dfr;
    MSE     = SSE/dfe;
    MSR     = (SST-SSE)/dfr;

    F       = MSR/MSE;
    P       = 1 - fcdf(F,dfr,dfe);
end
if nargout > 4
    CI      = nlparci(coefs,resid,J,ALPHA);
    ci      = CI';
end
