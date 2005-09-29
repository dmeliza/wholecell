function [rf, t] = LearningKernel(control, NBOOT)
%
% LEARNINGKERNEL plots the average change in the response at the induced
% position as a function of the temporal distance from the spike time. It
% is similar to CompositeRF in the 'induced' mode, but plots the data in
% larger bins, and quantifies the temporal window by fitting either side to
% an exponential decay function.
%
% LEARNINGKERNEL(CONTROL, NBOOT) takes a control file (see CompositeRF) that
% gives the location of pre and post RFs. 
%
% To get useful values for the confidence intervals of the exponential fit
% parameters it's necessary to do a bootstrap. The number of iterations is
% controlled by the NBOOT parameter.
%
%
% $Id$
%
% 1.3: Function no longer runs statistical tests on individual bins, as
% this is too sensitive to bin width

% Analysis constants
BINSIZE     = 15;       
LTD_DELTA   = [-65 -0.1];
LTP_DELTA   = [0    50];
WINDOW      = 200;
ALPHA       = 0.05;
Fs          = 10;
if nargin < 2
    NBOOT   = 1;      % # of iterations for the bootstrap
end

% Display constants
SZ      = [3.4 3.0];
PLMN    = char(177);    % the plus-minus character

% Load control data from file
[data, files]   = xlsread(control);
x_induced       = data(:,1);
t_spike         = data(:,2);
x_center        = data(:,3);
t_peak          = data(:,4);
t_onset         = data(:,5);

% generate the logical arrays that describe which experiments belong in
% which categories:
delta           = t_spike - t_peak;
ind_ltp         = delta >= LTP_DELTA(1) & delta <= LTP_DELTA(2);
ind_ltd         = delta >= LTD_DELTA(1) & delta <= LTD_DELTA(2);
ind_center      = x_induced == x_center;
ind_surround    = ~ind_center;

% ignore experiments that don't fall into either the LTP or LTD windows:
ind             = (ind_ltp | ind_ltd);
ind_ltp         = ind_ltp(ind);
ind_ltd         = ind_ltd(ind);
ind_center      = ind_center(ind);
ind_surround    = ind_surround(ind);
files           = files(ind,:);
x_induced       = data(ind,1);  % induced bar 
t_spike         = data(ind,2);  % time of spike
x_center        = data(ind,3);  % strongest response
t_center        = data(ind,4);  % induced peak
t_onset         = data(ind,5);  % time of onset of induced response
delta           = delta(ind);

% Load data from matfiles
trials  = length(files);
for i = 1:trials
    fprintf('%s: (delta = %d)\n',files{i,1},delta(i));
    [dd(:,:,i), aa(:,:,i), bb(:,:,i), T(:,i)]   = CompareRF(files{i,1},...
        files{i,2}, t_spike(i), x_induced(i), WINDOW);
end

% Rebin the data
dd      = BinData(dd,BINSIZE*Fs,1);
t       = linspace(-WINDOW,WINDOW,size(dd,1));

% Select delta curves from induced bars only; also, only the times that are
% expected to be affected are analyzed here (e.g. only t < 0 for LTP
% spikes). In some cases, of course, a spike will have multiple effects on
% a response, but this is the simplest way to eliminate cases where
% there is no response to be potentiated or depressed, which would
% otherwise distort the statistics
LTP_t       = t(t<0);
LTP         = select(dd(t<0,:,ind_ltp),x_induced(ind_ltp));
LTD_t       = t(t>0);
LTD         = select(dd(t>0,:,ind_ltd),x_induced(ind_ltd));

% Calculate mean and error for each bin
LTP_m   = mean(LTP,2);
LTP_e   = std(LTP,[],2) ./ sqrt(size(LTP,2));
LTD_m   = mean(LTD,2);
LTD_e   = std(LTD,[],2) ./ sqrt(size(LTD,2));

% Now we try to fit the data to single exponentials, using a nonparametric
% boostrap to estimate confidence intervals.
[coefs_p,expr,Rsq_p,P_p,ci_p] = expfit(LTP_t, LTP, NBOOT);
% for LTD we drop the first point since it's usually contaminated by the
% LTP side.
[coefs_d,expr,Rsq_d,P_d,ci_d] = expfit(LTD_t(2:end),LTD(2:end,:),NBOOT);

% print this at the end
fprintf('LTP Fit: A+ = %3.2f %s %3.2f%%, t+ = %3.2f %s %3.2f ms (R2 = %3.3f; P = %4.4f)\n',...
    coefs_p(1)*100+100, PLMN, ci_p(1)*100,...
    coefs_p(2), PLMN, ci_p(2), Rsq_p, P_p);
fprintf('LTD Fit: A- = %3.2f %s %3.2f%%, t- = %3.2f %s %3.2f ms (R2 = %3.3f; P = %4.4f)\n',...
    coefs_d(1)*100+100, PLMN, ci_d(1)*100,...
    coefs_d(2), PLMN, ci_d(2), Rsq_d, P_d);

% ---------------------------
% Plot the figure
f   = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)

% Plot the data and the curves
a1  = subplot(1,2,1);
hold on
errorbar(LTP_t, LTP_m, LTP_e, 'ko');
hline(0)
xfit = linspace(-WINDOW, 0, 50);
plot(xfit,expr(coefs_p,xfit))
set(a1,'XLim',[-WINDOW 0])

a2  = subplot(1,2,2);
hold on
errorbar(LTD_t, LTD_m, LTD_e, 'ko');
hline(0)
xfit = linspace(0, WINDOW, 50);
plot(xfit,expr(coefs_d,xfit))
set(a2,'YTickLabel','','XLim',[0 WINDOW]);

% adjust y axis scales
mx  = max(max(abs([get(a1,'Ylim') get(a2,'ylim')])));
set([a1 a2],'Box','On','YLim',[-mx mx]);
  
function [coefs, expr,Rsq,P,ci] = expfit(X, Y, NBOOT)
if NBOOT == 1
    [coefs,expr,Rsq,P,ci]   = ExpDecayFit(X, Y);
else
    % This is a somewhat unusual bootstrap in that we apply a selection
    % criteria. Some curves are not fittable and we have to apply some
    % selection criteria.
    [coefs, Rsq, P] = deal([]);
    sz  = size(Y,2);
    while(length(coefs) < NBOOT)
        select  = unidrnd(sz,sz,1);
        YY      = Y(:,select);
        [C,E,R,p] = ExpDecayFit(X, YY);
        [coefs(end+1,:)] = C;
        [Rsq(end+1)]     = R;
        [P(end+1)]       = p;
    end
    % A good criterion is to only keep the top 50% of fits. (Alternatively,
    % one could set a P threshhold)
    keep    = Rsq >= median(Rsq);
    ci      = std(coefs(keep,:));
    coefs   = mean(coefs(keep,:));
    ci      = repmat(coefs,2,1) + [ci; -ci];
    [Rsq, P] = CheckFit(X, mean(Y,2), coefs, E);
    expr    = E;
end
ci  = (ci(2,:) - ci(1,:))/2;

function out = select(data, columns)
% select a set of columns from a group of experiments
for i = 1:length(columns)
    out(:,i)    = data(:,columns(i),i);
end
