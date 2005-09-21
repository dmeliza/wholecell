function h  = whiskerbar(X, Y, YCI_L, YCI_U, P, ALPHA)
%
% Plots a bar graph with whiskers.
%
% h = WHISKERBAR(X, Y, Y_CI)
% h = WHISKERBAR(X, Y, Y_CI_L, Y_CI_U)
% h = WHISKERBAR(X, Y, Y_CI_L, Y_CI_U, P, ALPHA)
%
% X - the X vector (as with BAR)
% Y - the Y vector (as with BAR)
% Y_CI - confidence intervals for each value in Y.
% P - P values for each value in Y. If this argument is supplied, and the P
% value for a given point is less than ALPHA (default 0.05), a star will be
% plotted above the bar.
%
% If BAR is used in matrix mode, Y_CI must also be a matrix
%
% $Id$

h2    = [];
h3    = [];
if nargin < 6
    ALPHA = 0.05;
end

if size(Y,2) == 1
    Y   = Y(:);
end
if size(YCI_L,2) == 1
    YCI_L   = YCI_L(:);
end
if nargin < 4
    YCI_U   = YCI_L;
else
    if size(YCI_U,2) == 1
        YCI_U = YCI_U(:);
    end
end

mx    = max(max([Y + YCI_U]));

% this doesn't work with >R13's bar command
V     = str2num(version('-release'));
if V < 14
    h1    = bar(X,Y);
else
    h1    = bar('v6',X, Y);
end
ec    = get(h1(1),'EdgeColor');
set(h1,'Linewidth',2);

% plot error bar
hold on
for i = 1:length(h1)
    xdata   = get(h1(i),'XData');
    xc      = mean(xdata,1);        % each column is a bar
    if V < 14
        hh      = errorbar(xc, Y(:,i), YCI_L(:,i), YCI_U(:,i));
    else
        hh      = errorbar('v6',xc, Y(:,i), YCI_L(:,i), YCI_U(:,i));
    end
    delete(hh(2));                  % kill the connectors
    h2       = [h2,hh(1)];
    % plot significance stars
    if nargin > 4
        s   = P(:,i) < ALPHA;
        if any(s)
            yy  = repmat(mx * 1.2, size(xc(s)));
%            h3  = [h3;text(xc(s), yy, '*')];
            h3  = [h3;plot(xc(s), yy, 'k*')];
        end
    end
end

set(h2,'Color',ec,'LineWidth',2);
% set(h3,'FontSize',15)
hold off
ylim    = get(gca,'YLim');
set(gca,'YLim',[ylim(1) mx * 1.4]);

if nargout > 0
    h   = [h1;h2];
end

