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
DELTA   = [-65 50]; % only pre-post timings in this range are used
NAMES   = {'LTD/surr','LTP/surr','LTD/cent','LTP/cent','LTP','LTD','cent','surr','all'};

% load control data from file
[data, files]   = xlsread(control);
t_spike         = data(:,2);
t_peak          = data(:,4);
% determine which expt's have the right induction intervals
delta           = t_spike - t_peak;
ind             = find(delta >= DELTA(1) & delta <= DELTA(2));
% restrict analysis to those expts
files           = files(ind,:);
t_spike         = data(ind,2);  % time of spike
t_peak          = data(ind,4);  % induced peak
induction       = data(ind,1);  % induced bar 
x_center        = data(ind,3);  % strongest response
t_onset         = data(ind,5);  % time of onset of induced response

% cycle through files and load spatial RFs
trials  = length(files);
for i = 1:trials
    [pre_rf(i,:), pst_rf(i,:), pre_cm(i,1), pst_cm(i,1)] = CompareSpatialRF(files{i,1},...
        files{i,2}, induction(i));
    [m,peak(i,1)]           = max(pre_rf(i,:));
end

% compute derivative parameters
sgn     = -sign(pst_cm - induction);        % direction of expected shift
shift   = (pst_cm - pre_cm) .* sgn;         % amount of shift toward induction or away
i       = sub2ind(size(pst_rf),find(induction),induction);     % index for induced pts
STDP    = (pst_rf(i) - pre_rf(i))./pre_rf(i); % relative change in induced bar resp
isLTP   = t_spike >= t_peak;
iscenter= (induction - peak) == 0;

% Figure 1: Plot shift in RF as a function of LTP/LTD and center/surround
plotStats(shift, isLTP, iscenter, NAMES, 'Shift in RF Center');

% Figure 2: Compute width of RFs before and after induction
% this is somewhat ill-defined for a four-point RF, but it's basically:
% sigma = sqrt(sum((x-mu)^2 * y)/sum(y))
pre_sigma = getSigma(pre_rf, pre_cm);
pst_sigma = getSigma(pst_rf, pst_cm);
dff_sigma = pst_sigma - pre_sigma;      % increase or decrease in width
plotStats(dff_sigma, isLTP, iscenter, NAMES, 'Shift in RF Width');


function [] = plotStats(x, isLTP, iscenter, NAMES, y_label)
% Generates a figure window displaying the results of a statistic, broken
% down by LTP/LTD and center/surround
SZ      = [3.0 2.9];
XLIM    = [-2 2];

f       = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)
X{1}     = (x(~isLTP & ~iscenter));         % ltd_flank
X{2}     = (x(isLTP  & ~iscenter));         % ltp_flank
X{3}     = (x(~isLTP & iscenter));          % ltd_cent
X{4}     = (x(isLTP  & iscenter));          % ltp_cent
X{5}     = x(isLTP);                        % ltp
X{6}     = x(~isLTP);                       % ltd
X{7}     = x(iscenter);                     % center
X{8}     = x(~iscenter);                    % surr
X{9}     = x;                               % all
h   = bar([0 1 2 3 4 5 6 7 8],...
    [mean(X{1}) mean(X{2}) mean(X{3}) mean(X{4})...
     mean(X{5}) mean(X{6}) mean(X{7}) mean(X{8}) mean(X{9})]);
set(h,'FaceColor','none')
hold on
% compute significance and plot individual points
% significance really needs to be computed with ANOVA or somesuch since the
% columns are not independent
warning off MATLAB:divideByZero
for i = 1:length(NAMES)
    Y           = X{i};
    h2          = plot(i-1,Y, 'ko');
    set(h2,'Color',[0.7 0.7 0.7],'MarkerFaceColor',[0.7 0.7 0.7],'MarkerSize',4);
    [h,p]       = ttest(Y,0);
    P           = ranksum(Y,0);
    fprintf('%s: %1.3f +/- %1.3f, p = %1.3f (ttest), P = %1.3f (ranksum)\n',NAMES{i},...
        mean(Y), std(Y)/sqrt(length(Y)), p, P);
end

hline(0,'k')
set(gca,'XTickLabel',NAMES,'Box','On',...
    'Xlim',[-0.5 8.5])
ylabel(y_label)

function sigma = getSigma(rf, cm)
% computes the width of a curve about its center of mass
% this is somewhat ill-defined for a four-point RF, but it's basically:
% sigma = sqrt(sum((x-mu)^2 * y)/sum(y))
x       = repmat(1:size(rf,2),size(rf,1),1) - repmat(cm,1,size(rf,2));
y       = rf - repmat(min(rf,[],2),1,size(rf,2));
sigma   = sqrt(sum(x.^2 .* y,2) ./ sum(y,2));

