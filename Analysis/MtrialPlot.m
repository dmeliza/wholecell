function MtrialPlot(varargin)
% makes a nice plot of y vs x when there are multiple trials
% individual trials are displayed in gray, and the average is displayed in black.
%
% mtrialplot([x], y, [options])
% options can be 'correct', which subtracts out the baseline of the y traces
%
% $Id$
error(nargchk(1,3,nargin))
x = [];
options = '';

% assign arguments
if nargin == 1
    y = varargin{1};
elseif nargin == 3
    x = varargin{1};
    y = varargin{2};
    options = varargin{3};
else
    if isa(varargin{2},'char')
        y = varargin{1};
        options = varargin{2};
    else
        x = varargin{1};
        y = varargin{2};
    end
end
    
% correct baseline
y = double(y);
switch options
case 'correct'
    y_m = repmat(mean(y,1),length(y),1);
    y = y - y_m;
end

% plot results
figure;
set(gcf,'color',[1 1 1]);
if isempty(x)
    p = plot(y);
else
    p = plot(x,y);
end
set (p,'color',[0.7 0.7 0.7]);
hold on;
y_mean = mean(y,2);
if isempty(x)
    p = plot(y_mean);
else
    p = plot(x,y_mean);
end
set(p,'Color',[0 0 0],'Linewidth',2);