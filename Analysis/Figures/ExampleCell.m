function [] = ExampleCell(timecourse, pre, post, x_pos, t_spike)
%
% Script to produce a nifty example cell figure, as in figure 2 of the
% Neuron paper.
%
% EXAMPLECELL(timecourse, pretrace, posttrace, x_pos, [t_spike])
% TIMECOURSE is a matfile exported from episodeanalysis that has (at least)
% the time course of the response. PRETRACE and POSTTRACE are also from
% EpisodeAnalysis, the same files used by CompareRF.  X_POS must be
% supplied so that the right trace gets plotted.

% $Id$

FIGURE  = [3.25 2.5];
FIELD   = 'results';
XLABEL  = 'Time (min)';
YLABEL  = 'Response Amplitude (%s)';
START   = 200;          % start time of plot, ms
WIN     = [-10 510];    % length of plot (rel to START)
LIGHT   = [0 500];      % time when bar of light is on (rel to START)

error(nargchk(4,5,nargin))

z   = load(timecourse);
z   = z.results;
A   = load(pre);
B   = load(post);
if size(A.data,2) < x_pos
    error('Spatial index exceeds number of traces in data')
end

% Open the figure
f = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,FIGURE)

% set up the axes. This is one large lower axis for the time course and a
% smaller axis above it for the visual response
ax1     = subplot(2,1,2);   % bottom 1/2 of figure
hold on

% plot the timecourse
offset = 0;
for i = 1:length(z(1).(FIELD))
    t   = z(1).(FIELD)(i).abstime;
    v   = z(1).(FIELD)(i).value;
    t   = t - offset;
    h   = plot(t(v>0),v(v>0),'k.');
    set(h,'markersize',6)
    if i == 1
        mn  = mean(v(v>0)); % used to plot horizontal line
    end
    fprintf('%d traces\n',length(t));
end
% Make the plot pretty
h   = hline(mn,'k:');
set(h,'LineWidth',2)
% the user will have to adjust the Xlim by hand
ylim    = get(gca,'YLim');
h   = plot(z(1).results(1).abstime(end) + 2, ylim(2) * 0.8,'kv');
set(h,'MarkerFaceColor',[0 0 0]);
xlabel(XLABEL)
ylabel(sprintf(YLABEL,z(1).(FIELD)(i).units))

% Inset: right 2/3 of top 1/2 of figure
ax2 = subplot(2,3,[2 3]);
% Synchronize time variables
A.time  = double(A.time) * 1000 - START;
B.time  = double(B.time) * 1000 - START;
a_ind   = find(A.time >= WIN(1) & A.time <= WIN(2));
b_ind   = find(B.time >= WIN(1) & B.time <= WIN(2));
if length(a_ind) > length(b_ind)
    a_ind = a_ind(1:length(b_ind));
else
    b_ind = b_ind(1:length(a_ind));
end
% Get the traces
t       = A.time(a_ind);
a       = A.data(a_ind, x_pos);
b       = B.data(b_ind, x_pos);
% Remove DC offset
a       = a - mean(a(1:50));
b       = b - mean(b(1:50));
% Smooth things out, otherwise the plot will look jaggy
cutoff  = 100;
Fs      = 1/mean(diff(A.time)) * 1000;
a       = filterresponse(a,cutoff,3,Fs);
b       = filterresponse(b,cutoff,3,Fs);
% Plot
h       = plot(t,a,'k',t,b,'r');
% set(h,'LineWidth',2);
mx  = max(max([a b]));
mn  = min(min([a b]));
set(gca,'YLim',[mn * 1.1, mx * 1.1]);
% Draw spike time, if supplied
if nargin > 4
    vline(t_spike,'k-')     % the line style has to be adjusted in illustrator
end
axis tight
% Add the stimulus bar
hold on
y   = mx * 1.6;
h   = plot(LIGHT,[y y]);
set(h,'color','black','linewidth',2)
set(gca,'ylim',[mn * 1.1, mx * 1.7])

% Add the scale bar
xtick   = 100;
ytick   = 0;    % automatic
AddScaleBar(gca,{'ms','pA'}, [xtick ytick]);

% finally, adjust the size of the axes
% (this code is hardwired because I am lazy, but it should be in relative
% coordinates)
set(ax1,'Position',[0.1397    0.1583    0.7653    0.4042])
set(ax2,'Position',[0.5184    0.6000    0.3900    0.3250]);

function out = filterresponse(data, cutoff, order, Fs)
%data     = NotchFilter(data, 60, Fs, 20);
Wn      = double(cutoff/(Fs/2));
if Wn >= 1
    Wn = 0.999;
end
[b,a]   = butter(order,Wn);
out     = filtfilt(b,a,data);