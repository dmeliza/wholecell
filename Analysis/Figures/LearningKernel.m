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
WINDOW = 250;       % ms; switch to 250 for the wider window in fig 2
Fs     = 10;
SZ      = [3.4 2.9];
BINSIZE = 20;       % 4.3 gives a nice smooth curve

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
t       = linspace(-WINDOW,WINDOW,size(dd,1));

% generate the figure
f   = figure;
set(f,'Color',[1 1 1])
%ResizeFigure(f,SZ)

% we have to process LTP and LTD separately.
a1 = subplot(1,2,1);
LTP         = select(dd(:,:,ind_ltp),x_induced(ind_ltp));
ind         = find(t<0);
[A_p,t_p,expr]   = expfit(t(ind), LTP(ind,:));
fprintf('LTP Fit: A+ = %3.2f%%, t+ = %3.2f ms\n', A_p*100+100, t_p);
plot(t(ind), mean(LTP(ind,:),2),'ko');
fun     = inline(expr,'x','b');
hold on
fplot(fun,[-WINDOW 0],[],[],[],[A_p,t_p]);

a2 = subplot(1,2,2);
LTD         = select(dd(:,:,ind_ltd),x_induced(ind_ltd));
ind         = find(t>0);
% for LTD we drop the first point since it's usually contaminated by the
% LTP side
[A_d,t_d]   = expfit(t(ind(2:end)),LTD(ind(2:end),:));
fprintf('LTD Fit: A+ = %3.2f%%, t+ = %3.2f ms\n', A_d*100+100, t_d);
plot(t(ind), mean(LTD(ind,:),2),'ko');
fun     = inline(expr,'x','b');
hold on
fplot(fun,[0 WINDOW],[],[],[],[A_d,t_d]);

% adjust y axis scales
mx  = max(max(abs([get(a1,'Ylim') get(a2,'ylim')])));
set([a1 a2],'Box','On','YLim',[-mx mx]);
  

function [A, t, expr] = expfit(X, Y)
expr    = 'b(1) * exp(-abs(x)/b(2))';
fun     = inline(expr,'b','x');
X       = X(:);
Y       = mean(Y,2);
[mx,i]  = max(abs(Y));
beta0   = [Y(i), 20];
betaP   = nlinfit(X, Y, fun, beta0);
A       = betaP(1);
t       = betaP(2);

function out = select(data, columns)
% select a set of columns from a group of experiments
for i = 1:length(columns)
    out(:,i)    = data(:,columns(i),i);
end
