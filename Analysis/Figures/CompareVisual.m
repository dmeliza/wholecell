function [] = CompareVisual(pre, post, bar, time)
%
%
% Compares the average response to visual stimuluation in one or two files
%
%
% $Id$
START = 0.2;
WIN = [-100:6000];
YLIM = [-40 15];

A = load(pre)
B = load(post)

Ta = find(A.time >= START);
Ta = Ta(1);
Tb = find(B.time >= START);
Tb = Tb(1);

f   = figure;
set(f,'color',[1 1 1],'units','inches')
p   = get(f,'position');
set(f,'position',[p(1) p(2) 2.4 0.77])
a   = axes;
hold on;

Da  = A.data(WIN+Ta);
Db  = B.data(WIN+Tb);
Da  = Da - mean(Da(1:50));
Db  = Db - mean(Db(1:50));


pa  = plot(A.time(WIN+Ta),Da,'k');
pb  = plot(B.time(WIN+Tb),Db,'r');
%vline(START,'k:');
set(gca,'YLim',YLIM,'Xtick',[],'Ytick',[],'Xcolor',[1 1 1],'YColor',[1 1 1])

% draw scale lines
h1  = line(START + [0.300 0.380], [-40 -40]);
h2  = line(START + [0.380 0.380], [-40 -20]);
set([h1 h2],'color',[0 0 0],'linewidth',2);
text(START + 0.325,-50,'100 ms')
text(START + 0.390,-25,'20 pA')
% 
% % draw light bar
% h3  = line([START START+0.5], [10 10]);
% set(h3,'color',[0 0 0],'linewidth',5)

if nargin > 2
    vline(time,'k:')
end
