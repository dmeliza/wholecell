function [d, t] = CompareEvents(pre, post, time, binsize)
%
% Rasterifies two .r0 files, constructs the amplitude-weighted event time
% histogram, and compares the two.
%
% $Id$
SZ      =  [3.4    5.6];    % window size
BS      = 30;               % default binrate
THRESH  = 2;                % z-score
WIN     = 1000:8000;        % analysis window (samples)
NORM    = 1;                % normalize results?
xlim    = [-100 600];       % lock graphs to this XLIM
PP      = 1;                % plot both pre and post events?

if nargin > 3
    BS  = binsize;
end

A   = load('-mat',pre);
B   = load('-mat',post);

a   = double(A.r0.data(WIN,:));
b   = double(B.r0.data(WIN,:));
a   = bindata(a,BS,1);
b   = bindata(b,BS,1);
at  = bindata(A.r0.time(WIN),BS,1) * 1000 - 200;
bt  = bindata(B.r0.time(WIN),BS,1) * 1000 - 200;

AR  = -Rasterify(a,THRESH);
BR  = -Rasterify(b,THRESH);
AR(AR<0) = 0;
BR(BR<0) = 0;
AH  = mean(AR,2);
BH  = mean(BR,2);
mx  = max(AH);
if NORM
    d   = BH ./ mx - AH ./ mx;
else
    d   = BH - AH;
end
t   = at;

if nargout > 1
    return
end

f   = figure;
set(f,'color',[1 1 1],'name',pre)
ResizeFigure(f,SZ)
movegui('center')

subplot(4,1,1)
p       = imagesc(at,1:size(AR,2),AR');
set(gca,'XTickLabel',[],'Box','On');
xlim    = get(gca,'XLim');
if nargin > 2
    vline(time,'k:')
end
colormap(flipud(gray))
ylabel('Trial #')

if PP
    subplot(4,1,2)
    p       = imagesc(bt,1:size(BR,2),BR');
    set(gca,'XTickLabel',[],'Box','On');
    if nargin > 2
        vline(time,'k:')
    end
    ylabel('Trial #')
else
    p   = get(gca,'position');
    set(gca,'position',[p(1) 0.535 p(3) p(4) * 1.6]);
end

subplot(4,1,3)
h   = plot(at,AH,'k',bt,BH,'r');
set(h,'LineWidth',2)
if nargin > 2
    vline(time,'k:')
end
set(gca,'XTickLabel',[],'Box','On','XLim',xlim)
ylabel('Mean Event Size (pA)')

subplot(4,1,4)
h   = plot(at,d,'k');
if nargin > 2
    vline(time,'k:')
end
set(gca,'Box','On','Xlim',xlim)
set(h,'Linewidth',2)
xlabel('Time (ms)')
ylabel('Pre - Post (pA)')