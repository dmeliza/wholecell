function MtrialPlot(x,y)
% makes a nice plot of y vs x when there are multiple trials
% individual trials are displayed in gray, and the average is displayed in black.
%
% $Id$
figure;
set(gcf,'color',[1 1 1]);

plot(x,y,'color',[0.7 0.7 0.7]);
hold on;
y_mean = mean(y,2);
plot(x,y_mean,'k','linewidth',2);