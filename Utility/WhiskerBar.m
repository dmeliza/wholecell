function h  = whiskerbar(X, Y, YCI_L, YCI_U)
%
% Plots a bar graph with whiskers.
%
% h = WHISKERBAR(X, Y, Y_CI)
% h = WHISKERBAR(X, Y, Y_CI_L, Y_CI_U)
%
% X - the X vector (as with BAR)
% Y - the Y vector (as with BAR)
% Y_CI - confidence intervals for each value in Y. Can be a vector of the
% same length as Y, or a 2xN matrix with upper and lower confidence values.
%
% $Id$

h1    = bar(X, Y);
ec    = get(h1,'EdgeColor');
set(h1,'Linewidth',2);

hold on
if nargin > 3
    h2    = errorbar(X, Y, YCI_L, YCI_U);
else
    h2    = errorbar(X, Y, YCI_L);
end

set(h2(2),'LineStyle','none');
set(h2(1),'Color',ec,'LineWidth',2);
hold off

h   = [h1;h2];

