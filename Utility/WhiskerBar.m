function h  = whiskerbar(X, Y, YCI_L, YCI_U, P)
%
% Plots a bar graph with whiskers.
%
% h = WHISKERBAR(X, Y, Y_CI)
% h = WHISKERBAR(X, Y, Y_CI_L, Y_CI_U)
%
% X - the X vector (as with BAR)
% Y - the Y vector (as with BAR)
% Y_CI - confidence intervals for each value in Y.
%
% If BAR is used in matrix mode, Y_CI must also be a matrix
%
% $Id$

h2    = [];
if size(Y,1) == 1
    Y   = Y(:);
end
if size(YCI_L,1) == 1
    YCI_L   = YCI_L(:);
end
if nargin < 4
    YCI_U   = YCI_L;
else
    if size(YCI_U,1) == 1
        YCI_U = YCI_U(:);
    end
end
    
h1    = bar(X, Y);
ec    = get(h1(1),'EdgeColor');
set(h1,'Linewidth',2);

hold on
for i = 1:length(h1)
    xdata   = get(h1(i),'XData');
    xc      = mean(xdata,1);        % each column is a bar
    h       = errorbar(xc, Y(:,i), YCI_L(:,i), YCI_U(:,i));
    set(h(2),'LineStyle','none');       % kill the tee
    h2       = [h2,h(1)];
end

set(h2,'Color',ec,'LineWidth',2);
hold off

h   = [h1;h2];

