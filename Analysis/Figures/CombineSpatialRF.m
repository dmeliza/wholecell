function [] = CombineSpatialRF(control)
%
% Computes and combines some group values from spatial RFs.
% 1) shift in center of mass of the RFs
% 2) change in size of RF
% 3) spread of LTP/LTD
%
% COMBINESPATIALRF(control)
%
% Control file should contain the following fields:
% pre file/dir, post file/dir, induction bar, [spike time], RF Center
% (pos), RF center (time), [onset time (induced)]
%
% spike time field is not used but this makes it compatible with the
% control file used by CompositeRF
%
% $Id$
SZ      = [3.0 2.9];
XLIM    = [-2 2];
DELTA   = [-65 50]; % only pre-post timings in this range are used
NAMES   = {'LTD/surr','LTP/surr','LTD/cent','LTP/cent'};

% load control data from file
[data, files]   = xlsread(control);
t_spike         = data(:,2);
t_peak          = data(:,4);
% determine which expt's have the right induction intervals
delta           = t_spike - t_peak;
ind             = find(delta >= DELTA(1) & delta <= DELTA(2));
% restrict analysis to those expts
files           = files(ind,:);
t_spike         = data(ind,2);
t_peak          = data(ind,4);
induction       = data(ind,1);
x_center        = data(ind,3);
t_onset         = data(ind,5);  % time of onset of induced response

% cycle through files and load spatial RFs
trials  = length(files);
for i = 1:trials
    [pre_rf(i,:), pst_rf(i,:), pre_cm(i,1), pst_cm(i,1)] = CompareSpatialRF(files{i,1},...
        files{i,2}, induction(i), t_peak(i));
    [m,peak(i,1)]           = max(pre_rf(i,:));
end

% compute derivative parameters
sgn     = -sign(pst_cm - induction);        % direction of expected shift
shift   = (pst_cm - pre_cm) .* sgn;         % amount of shift toward induction or away
i       = sub2ind(size(pst_rf),find(induction),induction);     % index for induced pts
STDP    = (pst_rf(i) - pre_rf(i))./pre_rf(i); % relative change in induced bar resp
isLTP   = STDP > 0;
iscenter= (induction - peak) == 0;

% Figure 1: Plot shift in RF as a function of LTP/LTD and center/surround
f       = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)
ltd_flank     = (shift(~isLTP & ~iscenter));
ltp_flank     = (shift(isLTP  & ~iscenter));
ltd_cent      = (shift(~isLTP & iscenter));
ltp_cent      = (shift(isLTP  & iscenter));
% cent          = shift(iscenter);
h   = bar([0 1 2 3], [mean(ltd_flank) mean(ltp_flank) mean(ltd_cent) mean(ltp_cent)]);
% h   = bar([0 1 2], [mean(ltd_flank) mean(ltp_flank) mean(cent)]);
set(h,'FaceColor','none')
hold on
X   = isLTP + iscenter * 2;
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
    x       = pre_cm(ind) .* sgn(ind);
    y       = pst_cm(ind) .* sgn(ind);
    p       = signrank(x,y,0.95);
    Y       = shift(ind);
    [h,p]   = ttest(Y);
    fprintf('%s: %1.3f +/- %1.3f, p = %1.3f\n',NAMES{i},...
        mean(shift(ind)), std(shift(ind))/sqrt(length(ind)), p);
end
