function out = CompareRFFigure(rf1, rf2, bar, window, pos, mode)
%
% This is like CompareRF, but designed for producing example figures (no
% normalization
%
% $Id$
BINRATE = 53;
INTERP = 1;
THRESH = 1;
IMAGE  = 1;
NORM   = [1:100];
GAMMA   = 0.6;      % this needs to be fiddled with for individual files
BAR     = [0 500];
SZ      =  [3.2    2.2];

error(nargchk(4,6,nargin))

A = load(rf1);
B = load(rf2);
if isfield(A,'units')
    u = A.units;
else
    u = '';
end

win  = [bar - window, bar + window];
T    = double(A.time) * 1000 - 200;
Z    = find(T >= win(1));
t(1) = Z(1);
Z    = find(T <= win(2));
t(2) = Z(end);
t    = t(1):t(2);
T    = T(t);

t   = t(:);
a   = A.data(t,:);
b   = B.data(t,:);
if nargin > 5
    a   = a(:,pos);
    b   = b(:,pos);
end
ma  = mean(a(NORM,:),1);
mb  = mean(b(NORM,:),1);
a   = a - repmat(ma,length(t),1);
b   = b - repmat(mb,length(t),1);
d   = b - a;
if strcmpi(u,'pa')
    d   = -d;
end

% normalization is tricky because these are relative values.
% find the point of largest absolute difference, then use the ratio
% at that point. It may be better to use the peak of the pre-induction response?
% [m, i] = max(abs(d));
% [m, j] = max(abs(m));
% i      = i(j);
% val    = [a(i,j) b(i,j)];
% rat    = max(abs(val)) / min(abs(val));
% d      = d ./ m .* rat;

if size(a,2) == 1
    % for single traces
    figure
    ResizeFigure(SZ)
    subplot(2,1,1)
    h = plot(T,a,'k',T,b,'r');
    set(h,'Linewidth',1)
    axis tight
    mx  = max(max([a b]));
    mn  = min(min([a b]));
    set(gca,'ylim',[mn * 1.2, mx * 1.5]);
    AddScaleBar(gca,{'',u});
    set(gca,'xcolor','white','xticklabel','');
%    ylabel(['EPSC (' u ')']);
    vline(bar,'k:');
    
    subplot(2,1,2)
    h   = plot(T,d,'k');
    axis tight
    set(h,'Linewidth',2)
    vline(bar,'k:');
%    hline(0,'k:');
    AddScaleBar(gca,{'ms',''});
    %xlabel('Time (ms)');
    ylabel(['Delta (pA)']);
    
    out = struct('difference',d,'time',T,'t_induce',bar);
else
    % I'd prefer to have different colormaps for the RF and difference
    % plots, but I don't think this can be done in the same figure.
    [a,T] = smoothRF(a,T,BINRATE,INTERP);
    b     = smoothRF(b,T,BINRATE,INTERP);
    mx  = max(max(abs([a b])));
    figure,colormap(redblue(0.45,200))
    colormap(flipud(hot))
    ResizeFigure(SZ)
    if IMAGE
        n   = 2;        
        if strcmpi(u,'pa')
            a   = -a;
            b   = -b;
        end
        subplot(n+1,1,1)
        imagesc(T,1:size(a,2),a',[0 mx]);
        hold on
        colorbar
        set(gca,'YTick',[],'XTickLabel',[]);
        vline(0,'k');
        ylabel('Before');
        
        subplot(n+1,1,2)
        imagesc(T,1:size(b,2),b',[0 mx]);
        hold on
        colorbar
        vline(0,'k');
        set(gca,'YTick',[],'XTickLabel',[]);
        ylabel('After');
    else
        n = size(a,2);
        for i = 1:n
            subplot(n+1,1,i)
            plot(T,[a(:,i) b(:,i)]);
            vline(0,'k')
            vline(bar,'k:')
            set(gca,'XTickLabel',[]);
            ylabel(num2str(i))
        end
    end
    
    
    subplot(n+1,1,n+1)
    d     = smoothRF(d,T,BINRATE,INTERP);
    %d     = thresholdRF(d,THRESH);
    mx1   = max(max(abs(d)));
    if IMAGE
        imagesc(T,1:size(d,2),d',[-mx1 mx1]);
        set(gca,'Ytick',[]);
        colorbar
        if nargin < 5
            vline(bar,'w');
        else
            hold on
            pos     = pos * INTERP;
            plot(bar, pos,'k*')
        end
    else
        plot(T,d)
        vline(bar,'k:');
    end
    vline(0,'k');
    ylabel('Delta');
    xlabel('Time (s)');


    out = struct('difference',d,'time',T,'t_induce',bar,'x_induce',pos);    
end

function [d,T] = smoothRF(d,T,binrate,interp)
d   = bindata(d,binrate,1);
T   = bindata(T,binrate,1);
s   = size(d);
X   = linspace(1,s(2),s(2)*interp);  % interpolate in x dimension
t   = 1:s(1);
d   = interp2(d,X,t(:));

function [d] = thresholdRF(d,n)
% Flattens signal which does not exceed n standard deviations (from zero)
m   = mean(d(:));
%m   = 0;
s   = std(d(:)) * n;
th  = [m - s, m + s];
i   = (d > th(1)) & (d < th(2));
d(i) = m;

function [t,x] = centroid(d,T)
% computes the centroid of the RF.  Note that this function is
% meaningful only for positive valued d.
M   = sum(sum(d));
x   = sum(sum(d,1) .* (1:size(d,2)))/M;
t   = sum(sum(d,2) .* T)/M;
% t   = sum(sum(d,2) .* (1:size(d,1))')/M;
% t   = T(round(t));