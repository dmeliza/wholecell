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
induction       = data(:,1);
t_peak          = data(:,4);

trials  = length(files);
for i = 1:trials
    [pre_rf(i,:), pst_rf(i,:), pre_cm(i), pst_cm(i)] = CompareSpatialRF(files{i,1},...
        files{i,2}, induction(i), t_peak(i));
%     [pre(i,:),post(i,:)]  = SpatialRF(files{i,1}, files{i,2}, induction(i), t_peak(i));
%     pre_center(i)         = centroid(pre(i,:));
%     post_center(i)        = centroid(post(i,:));
    [m,peak(i)]           = max(pre_rf(i,:));
    sgn(i)                = -sign(pst_cm(i) - induction(i));   % used to normalize shifts
    shift(i)              = (pst_cm(i) - pre_cm(i)) .* sgn(i);
    STDP(i)               = ((pst_rf(i,induction(i)) - pre_rf(i,induction(i))))/pre_rf(i,induction(i)); 
    isLTP(i)              = STDP(i) > 0;
    iscenter(i)           = (induction(i) - peak(i)) == 0;
%    fprintf('%s: Shift from %3.2f to %3.2f (%3.2f)\n', files{i,1}, pre_center(i), post_center(i), shift(i));
end
keyboard
% Normalize
% mx      = max(pre_rf,[],2);
% mx      = repmat(mx,1,size(pre_rf,2));
% pre     = pre ./ mx;
% post    = post ./ mx;

% Compute difference
% change  = post - pre;
f       = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)
ltd_flank     = (shift(~isLTP & ~iscenter));
ltp_flank     = (shift(isLTP  & ~iscenter));
% ltd_cent      = (shift(~isLTP & iscenter));
% ltp_cent      = (shift(isLTP  & iscenter));
cent          = shift(iscenter);
%h   = bar([0 1 2 3], [mean(ltd_flank) mean(ltp_flank) mean(ltd_cent) mean(ltp_cent)]);
h   = bar([0 1 2], [mean(ltd_flank) mean(ltp_flank) mean(cent)]);
set(h,'FaceColor','none')
hold on
X   = isLTP + iscenter * 2;
X(X==3) = 2;
h2  = plot(X, shift, 'ko');
set(h2,'Color',[0.7 0.7 0.7],'MarkerFaceColor',[0.7 0.7 0.7],'MarkerSize',4);
hline(0,'k')
set(gca,'XTickLabel',NAMES,'Box','On',...
    'Xlim',[-0.5 3.5])
ylabel('Shift in RF (relative units)')

% compute significance - wilcoxon sign test
warning off MATLAB:divideByZero
for i = 1:length(NAMES)
    ind     = find(X==(i-1));
    x       = pre_center(ind) .* sgn(ind);
    y       = post_center(ind) .* sgn(ind);
    p       = signrank(x,y,0.95);
%     Y       = shift(ind);
%     [h,p]   = ttest(Y);
    fprintf('%s: %1.3f +/- %1.3f, p = %1.3f\n',NAMES{i},...
        mean(shift(ind)), std(shift(ind))/sqrt(length(ind)), p);
end

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