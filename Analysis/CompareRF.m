function out = compareRF(rf1, rf2, bar, window, pos)
%
% D = COMPARERF(rf1, rf2, bar, window, [pos])
%
% stupid little figure script that loads, normalizes, and compares
% two receptive fields (or reponse fields). plots equal amounts of time
% on either side of the bar position.  BAR and WINDOW are in units
% of time. POS is the number of the position which was induced.
% ver little error checking
%
% $Id$

error(nargchk(4,5,nargin))

A = load(rf1);
B = load(rf2);
if isfield(A,'units')
    u = A.units;
else
    u = '';
end

win  = [bar - window, bar + window];
Z    = find(A.time >= win(1));
t(1) = Z(1);
Z    = find(A.time <= win(2));
t(2) = Z(end);
t    = t(1):t(2);
T    = A.time(t);

% if nargin > 2
%     t   = window(1):window(2);
%     T   = A.time(t);
% else
%     T   = {A.time,B.time};
%     [m i] = max(cellfun('length',T));
%     T   = T{i};
%     t   = 1:length(T);
% end

t   = t(:);
a   = A.data(t,:);
b   = B.data(t,:);
ma  = mean(a(1:100,:),1);
mb  = mean(b(1:100,:),1);
a   = a - repmat(ma,length(t),1);
b   = b - repmat(mb,length(t),1);
d   = b - a;
if strcmpi(u,'pa')
    d   = -d;
end

% normalization is tricky because these are relative values.
% find the point of largest absolute difference, then use the ratio
% at that point
% [m, i] = max(abs(d));
% val    = [a(i) b(i)];
% rat    = max(abs(val)) / min(abs(val));
% d      = d ./ m .* rat;

out = struct('difference',d,'time',T,'t_induce',bar,'x_induce',pos);

if size(a,2) == 1
    figure
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
else
%     n = size(a,2);
%     mx  = mx + 0.1 * mx;
%     for i = 1:n
%         subplot(n+1,1,i)
%         plot(T,[a(:,i),b(:,i)]);
%         set(gca,'XtickLabel',[],'YLim',[-mx mx]);
%         ylabel(sprintf('%d (%s)',i,u));
%         vline(bar,'k:');
%         axis tight
%     end
    
    figure
    mx  = max(max(abs([a b])));
    n   = 2;
    subplot(n+1,1,1)
    [a,T] = smoothRF(a,T);
    a     = thresholdRF(a,0.5);
    imagesc(T,1:size(a,2),a',[-mx mx]);
    set(gca,'YTick',[],'XTickLabel',[]);
    vline(bar,'k');
    ylabel('Pre');
    
    subplot(n+1,1,2)
    d     = smoothRF(d,T);
    %d     = thresholdRF(d,1);
    mx1   = max(max(abs(d)));
    imagesc(T,1:size(d,2),d',[-mx1 mx1]);
    if nargin < 5
        vline(bar,'w');
    else
        hold on
        scatter(bar, pos, 10, 'w', 'filled')
    end
    set(gca,'Ytick',[],'XTickLabel',[]);
    ylabel('Post - Pre');
    
    subplot(n+1,1,3)
    b     = smoothRF(b,T);
    imagesc(T,1:size(b,2),b',[-mx mx]);
    set(gca,'YTick',[]);
    xlabel('Time (s)');
    ylabel('Post');
    %colorbar('horiz');
    
end

function [d,T] = smoothRF(d,T)
d   = bindata(d,52,1);
T   = bindata(T,52,1);
s   = size(d);
X   = linspace(1,s(2),s(2)*2);  % interpolate in x dimension
t   = 1:s(1);
d   = interp2(d,X,t(:));

function [d] = thresholdRF(d,n)
% Flattens signal which does not exceed n standard deviations (from zero)
m   = mean(d(:));
m   = 0;
s   = std(d(:)) * n;
th  = [m - s, m + s];
i   = (d > th(1)) & (d < th(2));
d(i) = m;