function [] = CompareElec(pre, post, time)
%
%
% Compares the average response to electrical stimuluation in two files
%
%
% $Id$
START = 0.2
WIN = [-100:6000];
YLIM = [-40 15];

A = load(pre)
B = load(post)

Ta = find(A.time==START);
Tb = find(B.time==START);

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
h1  = line(START + [0.2 0.3], [-30 -30]);
h2  = line(START + [0.3 0.3], [-30 -20]);
set([h1 h2],'color',[0 0 0],'linewidth',2);
text(START + 0.205,-35,'100 ms')
text(START + 0.305,-25,'10 pA')

% draw light bar
h3  = line([START START+0.5], [10 10]);
set(h3,'color',[0 0 0],'linewidth',5)

if nargin > 2
    vline(time,'k:')
end