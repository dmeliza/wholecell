function [] = CombineSpatialRF(control)
%
% Combines spatial RF graphs into a single plot.
%
% COMBINESPATIALRF(control)
%
% Control file should contain the following fields:
% pre file/dir, post file/dir, induction bar, [spike time], RF Center
% (pos), RF center (time)
%
% spike time field is not used but this makes it compatible with the
% control file used by CompositeRF
%
% $Id$
SZ      = [3.0 2.9];
XLIM    = [-2 2];

[data, files]   = xlsread(control);

trials  = length(files);
for i = 1:trials
    [pre(i,:),post(i,:)]  = SpatialRF(files{i,1}, files{i,2}, data(i,1), data(i,4));
end

% Normalize
mx      = max(pre,[],2);
mx      = repmat(mx,1,size(pre,2));
pre     = pre ./ mx;
post    = post ./ mx;

% Compute difference
change  = pre - post;

% Synchronize to induction/center
offset_offset = 4;                  % have to add this to make indices work
LTP             = cell(1,7);
LTD             = cell(1,7);
for i = 1:size(change,1)
    center  = data(i,1);
    peak    = data(i,3);
    fprintf('%s (%d, %d): ', files{i,1}, center, peak);
    for j = 1:size(change,2)
        i_off   = abs(center - j);      % relative distance to induced
        p_off   = abs(peak - j);        % relative distance to peak
        sign    = (p_off >= i_off) * -1 + (p_off < i_off);
        offset  = i_off * sign;
        fprintf('%d->%d ', j, offset);
        o       = offset + offset_offset;
        if change(i,center) > 0
            LTP{o}    = cat(1,LTP{o},change(i,j));
        else
            LTD{o}    = cat(1,LTD{o},change(i,j));
        end
    end
    fprintf('\n')
end

f   = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)
a1  = subplot(2,1,1);hold on;
a2  = subplot(2,1,2);hold on;


n       = (1:length(LTP)) - offset_offset;

for i = 1:length(LTP)
    p       = LTP{i};
    d       = LTD{i};
    [ltp(i), ltp_err(i)]    = meanerr(p);
    [ltd(i), ltd_err(i)]    = meanerr(d);
    if ~isempty(p)
        subplot(2,1,1)
        h   = plot(n(i),p,'k.');
        set(h,'Color',[0.6 0.6 0.6]);
    end
    if ~isempty(d)
        subplot(2,1,2)
        h   = plot(n(i),d,'k.');
        set(h,'Color',[0.6 0.6 0.6]);
    end
end
set(a1,'XTickLabel', [])
set([a1 a2], 'Box', 'On', 'XLim', XLIM * 1.1, 'XTick', n)

Z       = ltp_err ~= 0;
%h1      = errorbar(n(Z), ltp(Z), ltp_err(Z),'b');
subplot(2,1,1)
h1      = plot(n(Z), ltp(Z),'k');
hline(0)
Z       = ltd_err ~= 0;
%h2      = errorbar(n(Z), ltd(Z), ltd_err(Z),'r');
subplot(2,1,2)
h2      = plot(n(Z), ltd(Z),'k');
hline(0)
xlabel('Distance from Induced Bar')
h       = ylabel('Relative Change in Reponse') 
set(h,'Units','normalized')
p       = get(h,'position')
set(h,'position',[p(1) 1.2 p(3)]);

set([h1 h2],'Linewidth', 2)


%keyboard

function [m, e] = meanerr(points)
% calculates mean and standard error
[m,e] = deal(0);
if ~isempty(points)
    m   = mean(points);
    if length(points) > 1
        e   = std(points)/sqrt(length(points));
    else
        e   = 0;
    end
end