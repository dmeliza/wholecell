function [d, t] = CompareEvents(pre, post, time, binsize)
%
% Rasterifies two .r0 files, constructs the amplitude-weighted event time
% histogram, and compares the two.
%
% $Id$
SZ   =  [3.4    5.6];
SZ1  = [3.4    2];
SZ2  = [3.4    2.6];
PP   = 1;                % plot both pre and post?
BS   = 61;               % binrate
THRESH  = 2;          % z-score
WIN     = 1000:8000;        % samples to analyze
%DWIN    = -100:200;         % time to display
SCATTER = 1;
NORM    = 0;
xlim    = [-50 300];
N   = 4;
mode = 'amppsth';     % psth, amppsth, meanevent


if nargin > 3
    BS  = binsize;
end

A   = loadFile(pre);
B   = loadFile(post);

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
ARev     = AR > 0;
BRev     = BR > 0;


AH      = mean(AR,2);
BH      = mean(BR,2);
APSTH   = mean(ARev,2);
BPSTH   = mean(BRev,2);
switch mode
    case 'psth'
        AH  = APSTH;
        BH  = BPSTH;
        AR  = ARev;
        BR  = BRev;
    case 'amppsth'
    case 'meanevent'
        AH = AH ./ APSTH;
        BH = BH ./ BPSTH;
        AH(isnan(AH)) = 0;
        BH(isnan(BH)) = 0;
end
        
mx  = max(AH);
if NORM
    d   = BH ./ mx - AH ./ mx;
else
    d   = BH - AH;
end
t   = at;

if nargout > 1
    %return
end

f   = figure;
set(f,'color',[1 1 1],'name',pre)
ResizeFigure(f,SZ)
movegui('center')
if nargin > 2
    ind     = find(time >= at);
    time    = at(ind(end)) - (at(2)-at(1))/2;
else
    time    = [];
end

subplot(4,1,1)
p       = imagesc(at,1:size(AR,2),AR');
set(gca,'XTickLabel',[],'Box','On','Xlim',xlim);
%xlim    = get(gca,'XLim');
if nargin > 2
    vline(time,'k:')
end
colormap(flipud(gray))
ylabel('Trial #')

if PP
    subplot(4,1,2)
    p       = imagesc(bt,1:size(BR,2),BR');
    set(gca,'XTickLabel',[],'Box','On','XLim',xlim);
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
ylabel('wPSTH (pA)')

subplot(4,1,4)
h   = plot(at,d,'k');
if nargin > 2
    vline(time,'k:')
end
set(gca,'Box','On','Xlim',xlim)
set(h,'Linewidth',2)
xlabel('Time (ms)')
ylabel('Post - Pre (pA)')


function D  = loadFile(filename)
[pn fn ext] = fileparts(filename);
seqfile     = fullfile(pn,[fn '.txt']);
D           = load('-mat',filename);
if exist(seqfile)
    S       = load('-ascii',seqfile);
    fprintf('Applied sequence file to %s...\n',filename);
    D.r0.data   = D.r0.data(:,S,:);
end