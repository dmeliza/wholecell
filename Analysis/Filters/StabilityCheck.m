function [stable] = StabilityCheck(A);
% Checks the stability of a filter by checking for roots using Durbin
% step-down recursion.
%
% stable = StabilityCheck(A)
%
% A - the coefficients of A(z) (or the feedback coefficients in diff form)
% stable = 1 if stable, 0 if not
%
% From "Introduction to Digital Filters", Julius Smith
% http://ccrma-www.stanford.edu/~jos/filters/Testing_Filter_Stability_Matlab.html
%
% $Id$

N = length(A)-1; % Order of A(z)
stable = 1;      % stable unless shown otherwise
A = A(:);        % make sure it's a column vector
for i=N:-1:1
  rci=A(i+1);
  if abs(rci) >= 1
    stable=0;
    return;
  end
  A = (A(1:i) - rci * A(i+1:-1:2))/(1-rci^2);
  %disp(sprintf('A[%d]=',i)); A(1:i)'
end
