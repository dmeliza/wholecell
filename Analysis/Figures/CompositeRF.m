function [rf, t] = CompositeRF(control, mode)
%
% RF = COMPOSITERF(CONTROL, MODE)
%
% produces a composite temporal/spatial RF from multiple data sets.
% CONTROL is the name of an xls file with the following fields:
% pre file, post file, induction bar, spike time, RF center (x), RF center (t), onset latency (induced) 
%
% As of 1.7, a lot of the old modes were cleaned out, and the default is
% now to generate a master figure which compares the induced bars to
% uninduced bars from a variety of different angles.

% $Id$

error(nargchk(1,2,nargin))
if nargin < 2
    mode    = '';
end

LTD_DELTA   = [-65 -0.1];
LTP_DELTA   = [0    50];
WINDOW = 150;       % ms; switch to 250 for the wider window in fig 2
Fs     = 10;
SZ      = [6.3 3.0];
SE      = [1 1 1];        % if 1, plot standard error
PLOTFUN = @plotbar;
BINSIZE = 10;       % 4.3 gives a nice smooth curve

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
    fprintf('%s: (delta = %d) (x = %d) \n',files{i,1},delta(i),...
        abs(x_center(i)-x_induced(i)));
    [dd(:,:,i), aa(:,:,i), bb(:,:,i), T(:,i)]   = CompareRF(files{i,1},...
        files{i,2}, t_spike(i), x_induced(i), WINDOW);
end

% rebin the data
dd      = bindata(dd,BINSIZE*Fs,1);
t       = linspace(-WINDOW,WINDOW,size(dd,1));

% generate the figure
f   = figure;
set(f,'Color',[1 1 1])

% some specialty graphs (try to keep this shorter than in the last
% incarnation of this program!)
switch lower(mode)
    case 'display'
        % plots all the delta curves in separate windows
        for i = 1:size(dd,3)
            figure
            subplot(3,1,1)
            plot(t,dd(:,x_induced(i),i));
            title(files{i,1})
        end
            
    case 'induced'
        % plots ONLY the temporal "learning kernel"
        ResizeFigure(f,SZ)
        subplot(1,4,[2 3])
        black   = select(dd,x_induced);
        rf1     = mean(black,2);
        h       = plot(t,rf1,'k');
        mx      = max(max(abs(rf1)));
        axis tight
        set(gca,'Box','On','YLim',[-mx mx]);
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        title('LTP and LTD')
        % now plot the standard error for LTP and LTD separately
        if SE == 0
            SE  = 1;
        end
        LTD    = select(dd(:,:,ind_ltd),x_induced(ind_ltd));
        LTP    = select(dd(:,:,ind_ltp),x_induced(ind_ltp));
        LTP_rf  = mean(LTP,2);
        LTD_rf  = mean(LTD,2);
        LTD_er  = std(LTD,[],2)/sqrt(size(LTD,2)) .* SE;% * tinv(.975,size(LTP,2)-1);
        LTP_er  = std(LTP,[],2)/sqrt(size(LTD,2)) .* SE;% * tinv(.975,size(LTD,2)-1);
        LTP_ci  = [LTP_rf - LTP_er, LTP_rf + LTP_er];
        LTD_ci  = [LTD_rf - LTD_er, LTD_rf + LTD_er];
        mx      = max(max(abs([LTP_ci LTD_ci])));
        a1 = subplot(1,4,1);
            ind = find(t<0);
            tt  = t(ind);
            hold on
            plot(tt,LTP_rf(ind),'k');
            plot(tt,LTP_ci(ind,:),'k:');
            axis tight
            text(tt(size(tt,1))*.4,mx*.6,sprintf('(n = %d)',size(LTP,2)));
            title('LTP')
            ylabel('Change in EPSC (normalized)')
            hline(0)
        a2 = subplot(1,4,4);
            ind = find(t>0);
            tt  = t(ind);
            hold on
            plot(tt,LTD_rf(ind),'k');
            plot(tt,LTD_ci(ind,:),'k:');
            text(tt(size(tt,1))*.4,mx*.6,sprintf('(n = %d)',size(LTD,2)));
            title('LTD')
            axis tight
            hline(0)
        set([a1 a2],'Box','On','YLim',[-mx mx]);
        set(a2,'YAxisLocation','right');%'YTickLabel','')        
    otherwise
% the figure will be a grid of 9 graphs
% things are slightly complicated by the fact that when we're looking in
% the surround, we want to only look at the effect on the more central
% position

subplot(3,3,1)
ind     = ind_surround;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectcentralneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
feval(PLOTFUN,t, {black, blue} , {'flank','peak'},SE,'both');
title('LTP/LTD');
ylabel('Condition Surround');

subplot(3,3,2)
ind     = ind_surround & ind_ltp;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectcentralneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
feval(PLOTFUN,t, {black, blue}, {'flank','peak'},SE,'ltp');
title('LTP');

subplot(3,3,3)
ind     = ind_surround & ind_ltd;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectcentralneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
feval(PLOTFUN,t, {black, blue}, {'flank','peak'},SE,'ltd');
title('LTD');

subplot(3,3,4)
ind     = ind_center;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'peak','1','2'},SE,'both');
ylabel('Condition Center');

subplot(3,3,5)
ind     = ind_center & ind_ltp;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'peak','1','2'},SE,'ltp');

subplot(3,3,6)
ind     = ind_center & ind_ltd;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'peak','1','2'},SE,'ltd');

subplot(3,3,7)
black   = select(dd,x_induced);
blue    = selectneighbors(dd,x_induced);
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'cond','1','2'},SE,'both');
ylabel('All locations');

subplot(3,3,8)
ind     = ind_ltp;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'cond','1','2'},SE,'ltp');
xlabel('Time From Spike (ms)')

subplot(3,3,9)
ind     = ind_ltd;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'cond','1','2'},SE,'ltd');

colormap(gray)
end

function [] = plotbar(t, traces, legendary, SE, side)
% plots bar graphs with CI
% integrate over these windows:
ncond   = length(traces);
LTP_WIN = -30;
LTD_WIN = 80;
for i = 1:ncond
    [ltp_m(i), ltp_ci(i), ltp_p(i)] = integrate(traces{i},t<=0 & t>=LTP_WIN);
    [ltd_m(i), ltd_ci(i), ltd_p(i)] = integrate(traces{i},t>=0 & t<=LTD_WIN);
end
h    = whiskerbar(1:2,[ltp_m; ltd_m],[ltp_ci; ltd_ci],[ltp_ci;ltd_ci],[ltp_p;ltd_p]);
hline(0,'k')
switch lower(side)
    case 'ltp'
        set(gca,'XLim',[0.5 1.5],'XTickLabel',{''});
    case 'ltd'
        set(gca,'XLim',[1.5 2.5],'XTickLabel',{''});
    otherwise
        set(gca,'XTickLabel',{'dt<0','dt>0'});
end
z   = legend(h(1,:),legendary);

function [m, ci, p] = integrate(data, index)
A   = data(index,:);
A   = A(:);
m   = mean(A);
ci  = std(A)/sqrt(length(A));
[h,p]  = ttest(A);

function [] = plotcomparison(t, traces, legendary, SE)
% plots two traces with a legend. If SE > 0, plots the standard error * SE
% of the second trace
trcolors    = {'k','b','r','g'};
ncond       = length(traces);
for i = 1:ncond
    tr  = traces{i};
    rf  = mean(tr,2);
    h(i)    = plot(t, rf, trcolors{i});
    if SE(i) > 0
        rf_err  = std(tr,[],2) ./ sqrt(size(tr,2)) .* SE(i);
        hold on
        style   = [trcolors{i} ':'];
        hh      = plot(t, rf + rf_err, style, t, rf - rf_err, style);
    end
end
legend(h,legendary{:});
legend boxoff

axis   tight
mx    = max(abs(get(gca,'ylim')));
set(gca,'Box','On','YLim',[-mx mx]);
vline(0),hline(0)
text(t(size(rf,1))*.4,mx*.6,sprintf('(n = %d)',size(traces{1},2))); 

function out = select(data, columns)
% select a set of columns from a group of experiments
for i = 1:length(columns)
    out(:,i)    = data(:,columns(i),i);
end

function out = selectneighbors(data, columns, dist)
% select the neighbors of a column (e.g. if the column is 2, select 1,3)
% if DIST is supplied and > 1, then the neighbors at that distance will be
% returned
if nargin < 3
    dist  = 1;
end
out     = [];
valcols = 1:size(data,2);
for i = 1:length(columns)
    nind             = columns(i) + [-dist dist];
    nind             = intersect(nind, valcols);
    % average first:
    d                = mean(data(:,nind,i),2);
    out              = cat(2,out,d);
    % or average later?
%     for j = nind
%         out          = cat(2,out,data(:,j,i));
%     end
end

function out = selectcentralneighbor(data, columns, centers)
% select the more central neighbor of the column. If the column is already
% in the center, it will pick the same column, so be careful.
one_off = columns + sign(centers - columns);
out     = select(data, one_off);