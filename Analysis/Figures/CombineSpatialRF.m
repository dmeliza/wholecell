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
NAMES   = {'LTD/surr','LTP/surr','LTD/cent','LTP/cent'};

[data, files]   = xlsread(control);
induction       = data(:,1);
t_peak          = data(:,4);

trials  = length(files);
for i = 1:trials
    [pre(i,:),post(i,:)]  = SpatialRF(files{i,1}, files{i,2}, induction(i), t_peak(i));
    pre_center(i)         = centroid(pre(i,:));
    post_center(i)        = centroid(post(i,:));
    [m,peak(i)]           = max(pre(i,:));
    shift(i)              = (post_center(i) - pre_center(i)) .* -sign(post_center(i) - induction(i));
    STDP(i)               = ((post(i,induction(i)) - pre(i,induction(i))))/pre(i,induction(i)); 
    isLTP(i)              = STDP(i) > 0;
    iscenter(i)           = (induction(i) - peak(i)) == 0;
    fprintf('%s: Shift from %3.2f to %3.2f (%3.2f)\n', files{i,1}, pre_center(i), post_center(i), shift(i));
end

% Normalize
mx      = max(pre,[],2);
mx      = repmat(mx,1,size(pre,2));
pre     = pre ./ mx;
post    = post ./ mx;

% Compute difference
change  = post - pre;
f       = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)
ltd_flank     = (shift(~isLTP & ~iscenter));
ltp_flank     = (shift(isLTP  & ~iscenter));
ltd_cent      = (shift(~isLTP & iscenter));
ltp_cent      = (shift(isLTP  & iscenter));
h   = bar([0 1 2 3], [mean(ltd_flank) mean(ltp_flank) mean(ltd_cent) mean(ltp_cent)]);
set(h,'FaceColor','none')
hold on
X   = isLTP + iscenter * 2;
h2  = plot(X, shift, 'ko');
set(h2,'Color',[0.7 0.7 0.7],'MarkerFaceColor',[0.7 0.7 0.7],'MarkerSize',4);
hline(0,'k')
set(gca,'XTickLabel',NAMES,'Box','On',...
    'Xlim',[-0.5 3.5])
ylabel('Shift in RF (relative units)')

% compute significance
warning off MATLAB:divideByZero
for i = 1:length(NAMES)
    ind     = find(X==(i-1));
    Y       = shift(ind);
    [h,p]   = ttest(Y);
    fprintf('%s: p = %1.3f\n',NAMES{i},p);
end

% % Synchronize to induction/center
% offset_offset = 4;                  % have to add this to make indices work
% LTP             = cell(1,7);
% LTD             = cell(1,7);
% for i = 1:size(change,1)
%     center  = data(i,1);
%     peak    = data(i,3);
%     fprintf('%s (%d, %d): ', files{i,1}, center, peak);
%     for j = 1:size(change,2)
%         i_off   = abs(center - j);      % relative distance to induced
%         p_off   = abs(peak - j);        % relative distance to peak
%         sgn     = (p_off >= i_off) * -1 + (p_off < i_off);
%         offset  = i_off * sgn;
%         fprintf('%d->%d ', j, offset);
%         o       = offset + offset_offset;
% 
%         if change(i,center) > 0
%             LTP{o}    = cat(1,LTP{o},change(i,j));
%         else
%             LTD{o}    = cat(1,LTD{o},change(i,j));
%         end
%     end
%     fprintf('\n')
%     fprintf('Shift from %3.2f to %3.2f (%3.2f)\n', pre_center(i), post_center(i), shift(i));
% end
% 
% 
% return
% f   = figure;
% set(f,'Color',[1 1 1])
% ResizeFigure(f,SZ)
% a1  = subplot(2,1,1);hold on;
% a2  = subplot(2,1,2);hold on;
% 
% 
% n       = (1:length(LTP)) - offset_offset;
% 
% for i = 1:length(LTP)
%     p       = LTP{i};
%     d       = LTD{i};
%     [ltp(i), ltp_err(i)]    = meanerr(p);
%     [ltd(i), ltd_err(i)]    = meanerr(d);
%     if ~isempty(p)
%         subplot(2,1,1)
%         h   = plot(n(i),p,'k.');
%         set(h,'Color',[0.6 0.6 0.6]);
%     end
%     if ~isempty(d)
%         subplot(2,1,2)
%         h   = plot(n(i),d,'k.');
%         set(h,'Color',[0.6 0.6 0.6]);
%     end
% end
% set(a1,'XTickLabel', [])
% set([a1 a2], 'Box', 'On', 'XLim', XLIM * 1.1, 'XTick', n)
% 
% Z       = ltp_err ~= 0;
% %h1      = errorbar(n(Z), ltp(Z), ltp_err(Z),'b');
% subplot(2,1,1)
% h1      = plot(n(Z), ltp(Z),'k');
% hline(0)
% Z       = ltd_err ~= 0;
% %h2      = errorbar(n(Z), ltd(Z), ltd_err(Z),'r');
% subplot(2,1,2)
% h2      = plot(n(Z), ltd(Z),'k');
% hline(0)
% xlabel('Distance from Induced Bar')
% h       = ylabel('Relative Change in Reponse') 
% set(h,'Units','normalized')
% p       = get(h,'position')
% set(h,'position',[p(1) 1.2 p(3)]);
% 
% set([h1 h2],'Linewidth', 2)


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

function [x] = centroid(rf)
% computes the center of mass of a one-parameter receptive field
rf  = rf - min(rf);
M   = sum(rf);
x   = sum(rf .* (1:length(rf)))/M;