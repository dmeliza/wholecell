function [rf, t] = LearningKernel(control, mode)
%
% RF = LEARNINGKERNEL(CONTROL, MODE)
%
% this is very similar to CompositeRF, but is dedicated to figuring out the
% significance limits of the learning kernel.
%
% $Id$

error(nargchk(1,2,nargin))
if nargin < 2
    mode    = '';
end

LTD_DELTA   = [-65 -0.1];
LTP_DELTA   = [0    50];
WINDOW  = 200;       % ms; switch to 250 for the wider window in fig 2
ALPHA   = 0.05
R2_THRESH   = 0.90;  % minimum R2 value to count a fit.
Fs      = 10;
SZ      = [3.4 3.0];
BINSIZE = 15;       % 4.3 gives a nice smooth curve
NBOOT   = 300;      % # of iterations for the bootstrap
PLMN    = char(177);    % the plus-minus character

% load control data from file
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

% load data from matfiles
trials  = length(files);
for i = 1:trials
    fprintf('%s: (delta = %d)\n',files{i,1},delta(i));
    [dd(:,:,i), aa(:,:,i), bb(:,:,i), T(:,i)]   = CompareRF(files{i,1},...
        files{i,2}, t_spike(i), x_induced(i), WINDOW);
end

% rebin the data
dd      = bindata(dd,BINSIZE*Fs,1);
%t       = bindata(T,BINSIZE*Fs,1);
t       = linspace(-WINDOW,WINDOW,size(dd,1));

% generate the figure
f   = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)

% First, we evaluate P at each point in the curve to see if the binned
% point is significantly different from zero. This is very sensitive to the
% bin width.
LTP_t       = t(t<0);
LTP         = select(dd(t<0,:,ind_ltp),x_induced(ind_ltp));
LTD_t       = t(t>0);
LTD         = select(dd(t>0,:,ind_ltd),x_induced(ind_ltd));

% compute the stats with ANOVA
% % [LTP_an, tab, LTP_stats] = anova1(LTP',[],'off');
% [LTP_an, tab, LTP_stats] = anova2(LTP',1,'off');
% fprintf('LTP ANOVA: P = %3.3f\n', LTP_an(1));
% if LTP_an < ALPHA
%     [LTP_p, LTP_h]           = DunnettTest(LTP_stats,1,ALPHA);
% else
%     LTP_p   = repmat(NaN,size(LTP_t));
%     LTP_h   = zeros(size(LTP_t));
% end
% %X   = LTD(2:end,:);
% %[LTD_an, tab, LTD_stats] = anova1(X',[],'off');
% [LTD_an, tab, LTD_stats] = anova2(LTD',1,'off');
% fprintf('LTD ANOVA: P = %3.3f\n', LTD_an(1));
% if LTD_an < ALPHA
%     [LTD_p, LTD_h]           = DunnettTest(LTD_stats,size(LTD,1));
% else
%     LTD_p   = repmat(NaN,size(LTP_t));
%     LTD_h   = zeros(size(LTP_t));
% end

% calculate significance with ttest
for i=1:size(LTP,1)
%    [LTP_h(i) LTP_p(i)]   = ttest(LTP(i,:),0,ALPHA);
    [LTP_p(i) LTP_h(i)]  = ranksum(LTP(i,:),0,ALPHA);
end
for i=1:size(LTD,1)
%    [LTD_h(i) LTD_p(i)]   = ttest(LTD(i,:),0,ALPHA);
    [LTD_p(i) LTD_h(i)]  = ranksum(LTD(i,:),0,ALPHA);
end
LTP_h = LTP_p < ALPHA;
LTD_h = LTD_p < ALPHA;

% calculate error bars
LTP_m   = mean(LTP,2);
LTP_e   = std(LTP,[],2) ./ sqrt(size(LTP,2));
LTD_m   = mean(LTD,2);
LTD_e   = std(LTD,[],2) ./ sqrt(size(LTD,2));


% Now we try to fit the data to single exponentials, using a nonparametric
% boostrap to estimate confidence intervals.
[A_p, t_p, R2_p] = deal([]);
sz  = size(LTP,2);
if NBOOT == 1
    [A_p,t_p,R2_p,expr]   = expfit(LTP_t, LTP);
else
    while length(A_p) < NBOOT
        select  = unidrnd(sz,sz,1);
        Y       = LTP(:,select);
        [A, t, R2, expr]    = expfit(LTP_t,Y);
        [A_p(end+1),t_p(end+1),R2_p(end+1)] = deal(A, t, R2);
    end
end
keep    = R2_p >= median(R2_p);
A_p_std = std(A_p(keep));
t_p_std = std(t_p(keep));
A_p     = mean(A_p(keep));
t_p     = mean(t_p(keep));
% evaluate the R2 of the mean fit
fun     = inline(expr,'x','b');
SSreg   = sum(power([LTP_m' - fun(LTP_t,[A_p t_p])],2));
SStot   = sum(power([LTP_m - mean(LTP_m)],2));
R2_p    = 1 - SSreg/SStot;
% for LTD we drop the first point since it's usually contaminated by the
% LTP side. More sophisticated would be to find the peak...
[A_d, t_d, R2_d] = deal([]);
sz  = size(LTD,2);
if NBOOT == 1
    [A_d,t_d,R2_d]   = expfit(LTD_t(2:end),LTD(2:end,:));
else
    while length(A_d) < NBOOT
        select  = unidrnd(sz,sz,1);
        Y       = LTD(:,select);
        [A, t, R2]  = expfit(LTD_t(2:end),Y(2:end,:));
%        if R2 > R2_THRESH
            [A_d(end+1),t_d(end+1), R2_d(end+1)]   = deal(A, t, R2);
%        end
    end
end
keep    = R2_d >= median(R2_d);
A_d_std = std(A_d(keep));
t_d_std = std(t_d(keep));
A_d     = mean(A_d(keep));
t_d     = mean(t_d(keep));
% calculate R2
SSreg   = sum(power([LTD_m(2:end)' - fun(LTD_t(2:end),[A_d t_d])],2));
SStot   = sum(power([LTD_m(2:end) - mean(LTD_m(2:end))],2));
R2_d    = 1 - SSreg/SStot;

% print this at the end
fprintf('LTP Fit: A+ = %3.2f %s %3.2f%%, t+ = %3.2f %s %3.2f ms (R2 = %3.3f)\n',...
    A_p*100+100, PLMN, A_p_std*100, t_p, PLMN, t_p_std, R2_p);
fprintf('LTD Fit: A- = %3.2f %s %3.2f%%, t- = %3.2f %s %3.2f ms (R2 = %3.3f)\n',...
    A_d*100+100, PLMN, A_d_std*100, t_d, PLMN, t_d_std, R2_d);

% Plot the data and the curves
a1  = subplot(1,2,1);
hold on
%plot(LTP_t, LTP_m,'ko');
errorbar(LTP_t, LTP_m, LTP_e, 'ko');
if any(LTP_h)
    h   = plot(LTP_t(LTP_h), LTP_m(LTP_h), 'ko');
    set(h,'MarkerFaceColor','black');
end
hline(0)
fplot(fun,[-WINDOW 0],[],[],[],[A_p,t_p]);

a2  = subplot(1,2,2);
hold on
%plot(LTD_t, LTD_m,'ko');
errorbar(LTD_t, LTD_m, LTD_e, 'ko');
if any(LTD_h)
    h    = plot(LTD_t(LTD_h), LTD_m(LTD_h),'ko');
    set(h,'MarkerFaceColor','black');
end
hline(0)
fplot(fun,[0 WINDOW],[],[],[],[A_d,t_d]);
set(a2,'YTickLabel','');

% adjust y axis scales
mx  = max(max(abs([get(a1,'Ylim') get(a2,'ylim')])));
set([a1 a2],'Box','On','YLim',[-mx mx]);
  

function [A, t, R2, expr] = expfit(X, Y)
% fits to a single exponential, and checks goodness of fit
expr    = 'b(1) * exp(-abs(x)/b(2))';
fun     = inline(expr,'b','x');
X       = X(:);
Y       = mean(Y,2);
[mx,i]  = max(abs(Y));
beta0   = [Y(i), 20];
[betaP,R,J]   = nlinfit(X, Y, fun, beta0);
% check R2 and normality of residuals
SSreg   = sum(power(R,2));
SStot   = sum(power([Y - mean(Y)],2));
R2      = 1 - SSreg/SStot;
% okay, ignore the normality, there's probably too few points
A       = betaP(1);
t       = betaP(2);


function out = select(data, columns)
% select a set of columns from a group of experiments
for i = 1:length(columns)
    out(:,i)    = data(:,columns(i),i);
end
