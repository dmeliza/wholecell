function [d, t] = CompareEvents(pre, post, time)
%
% Rasterifies two .r0 files, constructs the amplitude-weighted event time
% histogram, and compares the two.
%
% $Id$
SZ  =  [3.4    4.6];
SZ1  = [3.4    2];
SZ2  = [3.4    2.6];
BS  = 50;               % binrate
THRESH  = 1.5;          % z-score
WIN = 1000:8000;        % samples
SCATTER = 1;
xlim    = [-100 600];


A   = load('-mat',pre);
B   = load('-mat',post);

a   = double(A.r0.data(WIN,:));
b   = double(B.r0.data(WIN,:));
a   = bindata(a,BS,1);
b   = bindata(b,BS,1);
at  = bindata(A.r0.time(WIN),BS,1) * 1000 - 200;
bt  = bindata(B.r0.time(WIN),BS,1) * 1000 - 200;

AR  = Rasterify(a,THRESH);
BR  = Rasterify(b,THRESH);
AH  = -mean(AR,2);
BH  = -mean(BR,2);
d   = BH - AH;
t   = at;

if nargout > 1
    return
end

if SCATTER
    f   = figure;
    set(f,'units','inches','color',[1 1 1])
    p   = get(f,'position');
    set(f,'position',[p(1) p(2) SZ1(1) SZ1(2)]);
    movegui('center')
    
    p       = imagesc(at,1:size(AR,2),AR');
    set(gca,'XTickLabel',[],'Box','On');
    xlim    = get(gca,'XLim');
    colormap(gray)
    ylabel('Trial #')
end

f   = figure;
set(f,'units','inches','color',[1 1 1])
p   = get(f,'position');
set(f,'position',[p(1) p(2) SZ2(1) SZ2(2)]);
movegui('center')

subplot(2,1,1)
h   = plot(at,AH,'k',bt,BH,'r');
set(h,'LineWidth',2)
if nargin > 2
    vline(time,'k:')
end
set(gca,'XTickLabel',[],'Box','On','XLim',xlim)
ylabel('Mean Event Size (pA)')

subplot(2,1,2)
h   = plot(at,BH - AH,'k');
if nargin > 2
    vline(time,'k:')
end
set(gca,'Box','On','Xlim',xlim)
set(h,'Linewidth',2)
xlabel('Time (ms)')
ylabel('Pre - Post (pA)')