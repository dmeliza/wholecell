function [coef, p, r2, ci] = LinFit(X, Y, ALPHA)
%
% LINFIT - Fit linear function to data
% 
% [coef] = LINFIT(X,Y) returns the coefficients of the first-order
% polynomial that fits the data Y best. It is equivalent to POLYFIT(X,Y,1)
%
% [coef, p, r2, ci] = LINFIT(X,Y,ALPHA) returns the confidence intervals
% of the coefficients, along with the R-squared value for the fit, and the
% P value for a nonzero slope. The default value for ALPHA is 0.05.
%
% Equations for computing f-statistics and CIs from
% http://www.facstaff.bucknell.edu/maneval/help211/fitting.html
%
% $Id$

error(nargchk(2,3,nargin));

N           = 1;    % order of the polynomial
if nargin < 3
    ALPHA   = 0.05;
end
X           = X(:);
Y           = Y(:);
[coef,S]    = polyfit(X, Y, N);

if nargout > 1
    
    Yp      = polyval(coef, X);
    SSE     = sum(power(Y - Yp,2));
    SST     = sum(power(Y - mean(Y),2));
    dfr     = N;
    dfe     = length(X) - 1 - dfr;
    MSE     = SSE/dfe;
    MSR     = (SST-SSE)/dfr;
    
    r2      = 1 - SSE/SST;
    F       = MSR/MSE;
    p       = 1 - fcdf(F,dfr,dfe);
end

if nargout > 3
    R     = S.R;                  % The "R" from A = QR
    d     = (R'*R)\eye(N+1);      % The covariance matrix
    d     = diag(d)';             % ROW vector of the diagonal elements
    MSE   = (S.normr^2)/S.df;     % variance of the residuals
    se    = sqrt(MSE*d);          % the standard errors
    t     = coef./se;             % observed T-values
    tval  = tinv([ALPHA/2; 1-ALPHA/2],dfe);
    width = tval*se;
    ci    = repmat(coef,size(width,1),1) + width;
end



    