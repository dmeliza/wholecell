function [] = CompareVisual(pre, post, bar, time)
%
%
% Compares the average response to visual stimuluation in one or two files.
%
% CompareVisual(prefile, postfile, [bar], [time]
%
% bar - the spatial position to use
% time - the time, in ms, of the spike
%
%
% $Id$
BAR     = 1;
START   = 0.2;
WIN     = [-0.01 .501];
LIGHT   = [0 500];      % time when bar of light is on

% check arguments
error(nargchk(2,4,nargin));
if nargin < 3
    bar = BAR;
elseif isempty(bar)
    bar = BAR;
end
if nargin < 4
    time = [];
end
    
A = load(pre);
B = load(post);
if size(A.data,2) < bar
    error('Spatial index exceeds number of traces in data')
end

% synchronize time variables
A.time  = double(A.time);
B.time  = double(B.time);
a_ind   = find(A.time >= (START + WIN(1)) & A.time <= (START + WIN(2)));
b_ind   = find(B.time >= START + WIN(1) & B.time <= START + WIN(2));
if length(a_ind) > length(b_ind)
    a_ind = a_ind(1:length(b_ind));
else
    b_ind = b_ind(1:length(a_ind));
end
% extract the data
t       = (A.time(a_ind) - START) * 1000;
a       = A.data(a_ind, bar);
b       = B.data(b_ind, bar);

% normalize means
a       = a - mean(a(1:50));
b       = b - mean(b(1:50));

% open the figure
figure
set(gcf,'color',[1 1 1])
ResizeFigure(gcf,[2.4 0.77])

% plot the data
hold on
pa  = plot(t,a,'k');
pb  = plot(t,b,'r');
axis tight

mx  = max(max([a b]));
mn  = min(min([a b]));
set(gca,'YLim',[mn * 1.1, mx * 1.1]);
% draw spike time, if supplied
if ~isempty(time)
    vline(time,'k:')
end

% draw stim bar
if ~isempty(LIGHT)
    y   = mx * 1.4;
    h   = plot(LIGHT,[y y]);
    set(h,'color','black','linewidth',3)
    set(gca,'ylim',[mn * 1.1, mx * 1.5])
end

xtick   = 100;
ytick   = 0;    % automatic
AddScaleBar(gca,{'ms','pA'}, [xtick ytick]);


