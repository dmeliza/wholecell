function [d, a, b, T] = compareRF(rf1, rf2, bar, window, pos, mode)
%
% D = COMPARERF(rf1, rf2, bar, window, [pos, mode])
%
% stupid little figure script that loads, normalizes, and compares
% two receptive fields (or reponse fields). plots equal amounts of time
% on either side of the bar position.  BAR and WINDOW are in units
% of time. POS is the number of the position which was induced.
% ver little error checking. If MODE is set to 'single', only the induced
% bar will be shown
%
% $Id$
BINRATE = 23;
INTERP  = 1;
THRESH  = 1;
IMAGE   = 1;
NORM    = 200;
SZ      = [3.5 3.5];

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
Fs   = mean(diff(T));
Z    = find(T >= win(1));
t(1) = Z(1);
t(2) = Z(1) + window * 2 / Fs - 1;
t    = t(1):t(2);
T    = T(t);

t   = t(:);
a   = A.data(t,:);
b   = B.data(t,:);
if nargin > 5
    a   = a(:,pos);
    b   = b(:,pos);
end
ma  = mean(a(1:200,:),1);
mb  = mean(b(1:200,:),1);
% ma  = mean(A.data([(t(1)-NORM):t(1) t(end):(t(end)+NORM)],:),1);
% mb  = mean(B.data([(t(1)-NORM):t(1) t(end):(t(end)+NORM)],:),1);
a   = a - repmat(ma,length(t),1);
b   = b - repmat(mb,length(t),1);
d   = b - a;
if strcmpi(u,'pa')
    d   = -d;
end

% normalization is tricky because these are relative values.
% find the point of largest absolute difference, then use the ratio
% at that point. It may be better to use the peak of the pre-induction response?
[m, i] = max(abs(d));
[m, j] = max(abs(m));
i      = i(j);
val    = [a(i,j) b(i,j)];
rat    = max(abs(val)) / min(abs(val));
d      = d ./ m .* rat;

if nargout > 0
    return
end

f       = figure;
set(f,'Color',[1 1 1],'Name',rf1)
ResizeFigure(f,SZ)

if size(a,2) == 1

    subplot(2,1,1)
    h = plot(T,[a b]);
    set(gca,'XtickLabel',[]);
    ylabel(['Response (' u ')']);
    legend(h,{'Pre','Post'});
    vline(bar,'k:');
    axis tight
    
    subplot(2,1,2)
    plot(T,d);
    vline(bar,'k:');
    xlabel('Time (s)');
    ylabel(['Diff (rel)']);
    axis tight
    
    out = struct('difference',d,'time',T,'t_induce',bar)
else
    [a,T] = smoothRF(a,T,BINRATE,INTERP);
    b     = smoothRF(b,T,BINRATE,INTERP);
    mx  = max(max(abs([a b])));
    colormap(redblue(0.45,200))
    if IMAGE
        n   = 2;        
        if strcmpi(u,'pa')
            a   = -a;
            b   = -b;
        end 
        subplot(n+1,1,1)
        imagesc(T,1:size(a,2),a',[-mx mx]);
        [t,x] = centroid(a.*(a>0) ,T);
        fprintf('Centroid (pre) = %3.2f, %3.4f\n',x,t);
        hold on,scatter(t, x, 10, 'k', 'filled')
        colorbar
        set(gca,'YTick',[],'XTickLabel',[]);
        vline(0,'k');
        ylabel('Pre');
        
        subplot(n+1,1,2)
        imagesc(T,1:size(b,2),b',[-mx mx]);
        [t,x] = centroid(b.*(b>0) ,T);
        fprintf('Centroid (post) = %3.2f, %3.4f\n',x,t);
        hold on,scatter(t, x, 10, 'k', 'filled')
        colorbar
        vline(0,'k');
        set(gca,'YTick',[],'XTickLabel',[]);
        ylabel('Post');
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
    ylabel('Post - Pre');
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