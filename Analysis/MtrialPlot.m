function MtrialPlot(x,y,options)
% makes a nice plot of y vs x when there are multiple trials
% individual trials are displayed in gray, and the average is displayed in black.
%
% mtrialplot(x, y, options)
% options can be 'correct', which subtracts out the baseline of the y traces
%
% $Id$
figure;
set(gcf,'color',[1 1 1]);
y = double(y);
if nargin > 2
    switch options
    case 'correct'
        y_m = repmat(mean(y,1),length(y),1);
        y = y - y_m;
    end
end    
plot(x,y,'color',[0.7 0.7 0.7]);
hold on;
y_mean = mean(double(y),2);
plot(x,y_mean,'k','linewidth',2);