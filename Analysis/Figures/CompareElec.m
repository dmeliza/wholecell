function [] = CompareElec(pre, post, time)
%
%
% Compares the average response to electrical stimuluation in two files
%
%
% $Id$
% units are in seconds
START = 0;
WIN = [-0.01 0.1];
% length of scale bars (ms and pA)
SCL = [20 10];

A = load(pre)
B = load(post)

% synchronize time variables
a_ind   = find(A.time >= (START + WIN(1)) & A.time <= (START + WIN(2)));
b_ind   = find(B.time >= START + WIN(1) & B.time <= START + WIN(2));
if length(a_ind) > length(b_ind)
    a_ind = a_ind(1:length(b_ind));
else
    b_ind = b_ind(1:length(a_ind));
end
t       = A.time(a_ind) * 1000;
a       = A.data(a_ind);
b       = B.data(b_ind);

% normalize the data means
a  = a - mean(a(1:50));
b  = b - mean(b(1:50));

% plot the data
f   = figure;
set(f,'color',[1 1 1],'units','inches')
p   = get(f,'position');
set(f,'position',[p(1) p(2) 2.4 0.77])
hold on;

pa  = plot(t,a,'k');
pb  = plot(t,b,'r');
set(gca,'YLim',YLIM,'Xtick',[],'Ytick',[],'Xcolor',[1 1 1],'YColor',[1 1 1])

% adjust axes and draw scale lines
axis tight
tt      = find(t>= 3);
mn      = min(min([a(tt) b(tt)]));
mx      = max(max([a(tt) b(tt)]));
set(gca,'YLim',[mn * 1.1, mx * 1.2]);
xlim    = get(gca,'XLim');
ylim    = get(gca,'YLim');
xx      = xlim(2) - SCL(1) * 2;
yy      = ylim(1) + diff(ylim) * 0.2;
h1  = plot([xx xx+SCL(1)],[yy yy],'k');
h2  = plot([xx+SCL(1) xx+SCL(1)],[yy yy+SCL(2)],'k');
text(xx+5, yy - 10, sprintf('%d ms',SCL(1)));
text(xx+SCL(1)+10, yy + SCL(2)/2, sprintf('%d pA',SCL(2)));
set([h1 h2],'linewidth',2)

% h1  = line(START + [0.06 0.080], [-30 -30]);
% h2  = line(START + [0.080 0.080], [-30 -20]);
% set([h1 h2],'color',[0 0 0],'linewidth',2);
% text(START + 0.065,-40,'20 ms')
% text(START + 0.085,-25,'10 pA')
% 
% % draw light bar
% h3  = line([START START+0.5], [10 10]);
% set(h3,'color',[0 0 0],'linewidth',5)

if nargin > 2
    vline(time,'k:')
end