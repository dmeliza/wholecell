function h = AddScaleBar(ax, units, scale)
%
% Replaces the axes scale box with a right angle scale bar
%
% h = ADDSCALEBAR(AXES, [UNITS], [SCALE])
%
% AXES - the handle for the axes to change
% UNITS - a 2x1 cell array containing the units of the x and y axes. If
% this is not supplied, the lines will not be labelled. If one or both of
% these is empty, the scale bar for that axis will not be generated. 
% SCALE - 2x1 array with the length of the x and y bars.  If this is not
% supplied, the distance between two ticks will be used.

TAG = 'cdm_scalebar';
doX = 1;
doY = 1;

if nargin < 2
    units   = {};
elseif isempty(units)
    units   = {};
else
    if isempty(units{1})
        doX = 0;
    end
    if isempty(units{2})
        doY = 0;
    end
end

% extract some data from the axes first
xtick   = get(gca,'XTick');
ytick   = get(gca,'YTick');

% placement is tricky, so we'll use the 2nd to the last ticks on the x and
% y axes
xx      = xtick(end-1);
yy      = ytick(2);

% set the length of the bars
autoscale = [diff(xtick(end-1:end)) diff(ytick(2:3))];
if nargin > 2
    if scale(1) ~= 0
        autoscale(1) = scale(1);
    end
    if scale(2) ~= 0
        autoscale(2) = scale(2);
    end
end
scale = autoscale;

% clear the matlab axes and any existing scalebar objects
set(ax,'Box','Off');
h   = [];
if doX
    set(ax,'xcolor',[1 1 1],'XTickLabel','');
end
if doY 
    set(ax,'ycolor',[1 1 1],'YTickLabel','');
end

old_h   = findobj(gca, 'tag', TAG);

% draw the lines
hold on
if doX
    h(end+1)    = plot([xx xx+scale(1)],[yy yy],'k');
    if ~isempty(units)
        h(end+1)    = text(xx,yy - scale(2),sprintf('%d %s',scale(1),units{1}));
    end
end
if doY
    h(end+1)    = plot([xx+scale(1) xx+scale(1)], [yy yy+scale(2)],'k');
    if ~isempty(units)
        h(end+1)    = text(xx + scale(1)*1.1, yy + scale(2)/2, sprintf('%d %s',scale(2),units{2}));    
    end
end
%set(h,'Linewidth',2)
% labels. position is tricky because their height is relative to the axes,
% not to the scale. Fortunately the user can adjust this later.

if ~isempty(h)
    set(h,'tag',TAG)
end


% add a buttondown fxn to the scalebar object so that the user can move it
% around
% set(h,'buttondownfcn',{@clickScaleBar,h})
% 
% function [] = clickScaleBar(obj, event, h)
% keyboard
% start_x     = get(h,'XData');
% start_y     = get(h,'YData');
% dragHandler = {@dragMark,h};
% releaseHandler = {@releaseMark,h};
% set(gcf,'WindowButtonMotionFcn',dragHandler);
% set(gcf,'WindowButtonUpFcn',releaseHandler);
% 
% function [] = dragMark(obj,event)
