function [] = CompareVisual(pre, post, bar, time)
%
%
% Compares the average response to visual stimuluation in one or two files
%
%
% $Id$
START = 0.2
WIN = [-100:6000];
YLIM = [-40 15];

A = load(pre)
Ta = find(A.time >= START);
Ta  = Ta(1);
Da  = A.data(WIN+Ta,:);

if nargin > 1
    B   = load(post)
    Tb  = find(B.time >= START);
    Tb  = Tb(1);
    Db  = B.data(WIN+Tb,:);
else
    Db  = [];
    pb  = [];
end

f   = figure;
set(f,'color',[1 1 1],'units','inches')
p   = get(f,'position');
set(f,'position',[p(1) p(2) 2.6 3.8])

sz  = size(Da,2);
for i = 1:size(Da,2)
    ax(i)   = subplot(sz,1,i);
    hold on
    a       = Da(:,i) - mean(Da(1:50,i));
    pa(i)   = plot(A.time(WIN+Ta),a,'k');
    if ~isempty(Db)
        b       = Db(:,i) - mean(Db(1:50,i));
        pb(i)   = plot(B.time(WIN+Tb),b,'r');
    end
    axis tight
end

% plot formatting
YLIM    = [-max(max(abs([Da Db]))) 25];
set(ax,'YLim',YLIM,'Xtick',[],'Ytick',[],'Xcolor',[1 1 1],'YColor',[1 1 1])
set(pa,'LineWidth',2);
if ~isempty(pb)
    set(pb,'LineWidth',2);
end

% draw scale lines
axes(ax(end));
yps = YLIM(1) * 0.8;
xps = START + 0.4;
h1  = line([xps-0.1 xps], [yps yps]);
h2  = line([xps xps], [yps yps+20]);
set([h1 h2],'color',[0 0 0],'linewidth',2);
text(xps - 0.1,yps-10 ,'100 ms')
text(xps + 0.05,yps+10,'20 pA')

% draw light bar
axes(ax(1));
h3  = line([START START+0.5], [25 25]);
set(h3,'color',[0 0 0],'linewidth',5)

if nargin > 2
    subplot(sz,1,bar)
    vline(time,'k:')
end