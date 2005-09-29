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
%PLOTFUN = @plotcomparison;
BINSIZE = 10;       % 4.3 gives a nice smooth curve
GRID    = 2;        % a 3x3 grid or a 2x2 grid

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
dd      = BinData(dd,BINSIZE*Fs,1);
aa      = BinData(aa,BINSIZE*Fs,1);
bb      = BinData(bb,BINSIZE*Fs,1);
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
            subplot(2,1,1)
            plot(t,aa(:,x_induced(i),i),'k',...
                t,bb(:,x_induced(i),i),'r')
            subplot(2,1,2)
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
        LTD_er  = std(LTD,[],2)/sqrt(size(LTD,2)) .* SE(1);% * tinv(.975,size(LTP,2)-1);
        LTP_er  = std(LTP,[],2)/sqrt(size(LTD,2)) .* SE(1);% * tinv(.975,size(LTD,2)-1);
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
    case 'scatter'
        LTP_WIN = -30;
        LTD_WIN = 80;        
        for i = 1:trials
                bla_pre = aa(:,x_induced(i),i);
                black   = dd(:,x_induced(i),i);
                if ind_surround(i)
                    blue    = dd(:,x_center(i),i);
                    blu_pre = aa(:,x_center(i),i);
                    if ind_ltp(i)
                        GROUP{i}    = 'LTP/SUR';
%                         INDUCED(i)  = integrate(black,t<=0 & t>=LTP_WIN);
                    else
                        GROUP{i}    = 'LTD/SUR';
%                         INDUCED(i)  = integrate(black,t<=LTD_WIN & t>=0);
                    end
                else
                    blue    = selectneighbors(dd(:,:,i),x_induced(i));
                    blu_pre = selectneighbors(aa(:,:,i),x_induced(i));
                    if ind_ltp(i)
                        GROUP{i}    = 'LTP/CEN';
%                         INDUCED(i)  = integrate(black,t<=0 & t>=LTP_WIN);
                    else
                        GROUP{i}    = 'LTD/CEN';
%                         INDUCED(i)  = integrate(black,t<=LTD_WIN & t>=0);
                    end
                end
                INDUCED(i)  = integrate(black,t<=LTD_WIN & t >=LTP_WIN);
%                 PREIND(i)  = integrate(bla_pre,t<=LTD_WIN & t >=LTP_WIN);
                NONIND(i)   = integrate(blue,t<=LTD_WIN & t>=LTP_WIN);
%                 PRENON(i)  = integrate(blu_pre,t<=LTD_WIN & t>=LTP_WIN);
                
        end
        % convert relative change to log
        INDUCED = log(INDUCED+1);
        NONIND = log(NONIND+1);
        
%         ax = subplot(2,2,1);
%         gscatter(delta,INDUCED,GROUP')
%         hline(0),vline(0)
%         legend(ax,'off')
%         
%         ax = subplot(2,2,2);
%         gscatter(delta,NONIND,GROUP');
%         hline(0),vline(0)
%         legend(ax,'off');
        % this is the more informative plot:
%         subplot(2,2,[3 4])
%         gscatter(INDUCED,NONIND,GROUP')
%         [coefs, p, rsq] = LinFit(INDUCED,NONIND);
%         xpred   = [min(INDUCED) max(INDUCED)];
%         ypred   = polyval(coefs, xpred);
%         hold on
%         plot(xpred,ypred,'k');
%         hline(0),vline(0)
%         axis square
%         keyboard

        % this will actually go in the paper:
        ax = subplot(2,2,[3 4]);
        hold on
        h   = plot(INDUCED, NONIND, 'ko');
        set(h,'MarkerSize',6)
        % compute and plot the linear fit
        [coefs, p, rsq] = LinFit(INDUCED,NONIND);
        fprintf('Fit: y = %3.2fx + %3.2f; Rsq = %3.4f, p = %4.4f\n',...
            coefs(1), coefs(2), rsq, p)
        xpred   = [min(INDUCED) max(INDUCED)];
        ypred   = polyval(coefs, xpred);
        h       = plot(xpred,ypred,'k');
        set(h,'LineWidth',2)
        % convert the units on the axes to their nonlog values
        % we pretty much have to hard-wire them in to make it look good
        tk      = [50 100 200];
        lt      = log(tk/100);
        set(ax,'XLim',[lt(1) lt(end)],'YLim',[lt(1) lt(end)],...
            'XTick',lt,'YTick',lt,...
            'XTickLabel',num2str(tk'),'YTickLabel',num2str(tk'));
        % Finalize the plot
        plot([lt(1) lt(end)],[lt(1) lt(end)],'k:')
        hline(0,'k:'),vline(0,'k:')
        xlabel('Paired \DeltaResponse (%)');
        ylabel('Unpaired \DeltaResponse (%)');
        set(ax,'Position',[0.2179    0.1100    0.4714    0.5281],...
            'Box','On');
        axis square
%         keyboard
    case 'rel-change'
        % plots the change in induced and noninduced bars as a function of
        % their relative strength in the pre-induction RF. 
        LTP_WIN = -30;
        LTD_WIN = 80;
        % keep track of spike timing to see if there's a dissociation
        for i = 1:trials
            for j = 1:size(aa,2)
                bla_pst = integrate(bb(:,j,i),t<=LTD_WIN & t >=LTP_WIN);
                bla_pre = integrate(aa(:,j,i),t<=LTD_WIN & t >=LTP_WIN);
                PRE(i,j)    = bla_pre;
                PST(i,j)    = bla_pst;
                DELTA(i,j)  = log(bla_pst / bla_pre);
                INDUCED(i,j)= j==x_induced(i);
                dt(i,j)     = delta(i);
            end
        end
        PRE = PRE ./ repmat(max(PRE,[],2),1,size(PRE,2));
        % eliminate nonsense values (<=0)
        sel = PRE(:)>0 & PST(:)>0;
        PRE = PRE(sel);
        DELTA = DELTA(sel);
        INDUCED = INDUCED(sel);
        dt      = dt(sel);
%         plot(PRE(INDUCED), DELTA(INDUCED), 'r.',...
%             PRE(~INDUCED),DELTA(~INDUCED),'b.');
        plot(PRE(~INDUCED), DELTA(~INDUCED), 'ko');
        % fit blue points
        hold on
        [coef,p,r2,ci] = LinFit(PRE(~INDUCED),DELTA(~INDUCED));
        xfit = linspace(min(PRE(~INDUCED)),max(PRE(~INDUCED)),2);
        h   = plot(xfit,polyval(coef,xfit),'k');
        set(h,'LineWidth',2);
        fprintf('linfit: m = %3.2f±%3.2f, b = %3.2f±%3.2f, P = %4.4f, Rsq = %3.3f\n',... 
            coef(1), ci(1,1) - coef(1), coef(2), ci(1,2) - coef(2), p, r2);
        % Relabel the Y axis with unlogged units
        % We have to hand-pick the ticks if we don't want bizarre %'s
%         ytk  = [5 15 50 100 300 750 2000];
        ytk  = [10 100 1000];
        ylt  = log(ytk/100);
        set(gca,'YTick',ylt,'YTickLabel',num2str(ytk'));
        % Finalize the plot    
        hline(0,'k:'),xlabel('Initial Response (% of Peak)')
        ylabel('Unpaired \DeltaResponse (%)')
%         legend({'induced','noninduced'});
        set(gca,'Position',[0.2179    0.1100    0.4714    0.5281],...
            'Box','On');
        axis square
        xtk  = get(gca,'XTick');
        xpk  = xtk * 100;
        set(gca,'XTickLabel',num2str(xpk'));
        
%         keyboard
    otherwise
% the figure will be a grid of 9 graphs
% things are slightly complicated by the fact that when we're looking in
% the surround, we want to only look at the effect on the more central
% position
pind    = 1;

if GRID > 2
    subplot(GRID,GRID,pind)
    pind    = pind + 1;
    ind     = ind_surround;
    black   = select(dd(:,:,ind),x_induced(ind));
    blue    = selectcentralneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
    red     = selectflankneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
    feval(PLOTFUN,t, {black, blue, red} , {'flank(induced)','peak','flank(uninduced)'},SE,'both');
    title(sprintf('LTP/LTD (n=%d)',size(black,2)));
    ylabel('Condition Flank');
end

subplot(GRID,GRID,pind)
pind    = pind + 1;
ind     = ind_surround & ind_ltp;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectcentralneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
red     = selectflankneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
feval(PLOTFUN,t, {black, blue, red}, {'flank(induced)','peak','flank(uninduced)'},SE,'ltp');
title(sprintf('LTP (n=%d)',size(black,2)));
if GRID == 2
    ylabel('Condition Flank');    
end

subplot(GRID,GRID,pind)
pind    = pind + 1;
ind     = ind_surround & ind_ltd;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectcentralneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
red     = selectflankneighbor(dd(:,:,ind),x_induced(ind),x_center(ind));
feval(PLOTFUN,t, {black, blue, red}, {'flank(induced)','peak','flank(uninduced)'},SE,'ltd');
title(sprintf('LTD (n=%d)',size(black,2)));
if GRID == 2
    ylabel('Condition Peak');    
end

if GRID > 2
    subplot(GRID,GRID,pind)
    pind    = pind + 1;
    ind     = ind_center;
    black   = select(dd(:,:,ind),x_induced(ind));
    blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
    red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
    feval(PLOTFUN,t, {black, blue, red}, {'peak','1','2'},SE,'both');
    ylabel('Condition Peak');
    title(sprintf('(n=%d)',size(black,2)));
end

subplot(GRID,GRID,pind)
pind    = pind + 1;
ind     = ind_center & ind_ltp;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'peak','1','2'},SE,'ltp');
title(sprintf('(n=%d)',size(black,2)));
    
subplot(GRID,GRID,pind)
pind    = pind + 1;
ind     = ind_center & ind_ltd;
black   = select(dd(:,:,ind),x_induced(ind));
blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
feval(PLOTFUN,t, {black, blue, red}, {'peak','1','2'},SE,'ltd');
title(sprintf('(n=%d)',size(black,2)));

if GRID > 2
    subplot(GRID,GRID,pind)
    pind    = pind + 1;
    black   = select(dd,x_induced);
    blue    = selectneighbors(dd,x_induced);
    red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
    feval(PLOTFUN,t, {black, blue, red}, {'cond','1','2'},SE,'both');
    title(sprintf('(n=%d)',size(black,2)));
    ylabel('All locations');
    
    subplot(GRID,GRID,pind)
    pind    = pind + 1;
    ind     = ind_ltp;
    black   = select(dd(:,:,ind),x_induced(ind));
    blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
    red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
    feval(PLOTFUN,t, {black, blue, red}, {'cond','1','2'},SE,'ltp');
    title(sprintf('(n=%d)',size(black,2)));
    xlabel('Time From Spike (ms)')
    
    subplot(GRID,GRID,pind)
    pind    = pind + 1;
    ind     = ind_ltd;
    black   = select(dd(:,:,ind),x_induced(ind));
    blue    = selectneighbors(dd(:,:,ind),x_induced(ind));
    red     = selectneighbors(dd(:,:,ind),x_induced(ind),2);
    feval(PLOTFUN,t, {black, blue, red}, {'cond','1','2'},SE,'ltd');
    title(sprintf('(n=%d)',size(black,2)));
end

colormap(gray)
end

function [] = plotbar(t, traces, legendary, SE, side)
% plots bar graphs with CI
% integrate over these windows:
ncond   = length(traces);
LTP_WIN = -30;
LTD_WIN = 80;
SEPARATE_SIDES = 0;
if SEPARATE_SIDES
    for i = 1:ncond
        [ltp_m(i), ltp_ci(i), ltp_p(i)] = integrate(traces{i},t<=0 & t>=LTP_WIN);
        [ltd_m(i), ltd_ci(i), ltd_p(i)] = integrate(traces{i},t>=0 & t<=LTD_WIN);
    end
    h    = WhiskerBar(1:2,[ltp_m; ltd_m],[ltp_ci; ltd_ci],[ltp_ci;ltd_ci],[ltp_p;ltd_p]);
else
    for i = 1:ncond
        [m(i), ci(i), p(i)] = integrate(traces{i},t<=LTD_WIN & t>=LTP_WIN);
    end
    h    = WhiskerBar(1:2,[m;m],[ci;ci],[ci;ci],[p;p]);
end
hline(0,'k')
if SEPARATE_SIDES
    switch lower(side)
        case 'ltp'
            set(gca,'XLim',[0.5 1.5],'XTickLabel',{''});
        case 'ltd'
            set(gca,'XLim',[1.5 2.5],'XTickLabel',{''});
        otherwise
            set(gca,'XTickLabel',{'dt<0','dt>0'});
    end
else
    set(gca,'XLim',[0.5 1.5],'XTickLabel',{''});
end
z   = legend(h(1,:),legendary);

function [m, ci, p] = integrate(data, index)
A   = data(index,:);
A   = A(:);
m   = mean(A);
ci  = std(A)/sqrt(length(A));
[h,p]  = ttest(A);

function [] = plotcomparison(t, traces, legendary, SE, ignore)
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

function out = selectflankneighbor(data, columns, centers)
% select the more flanking neighbor of the column. If the column is
% already the center, it will pick the same column, so be careful
one_off = columns - sign(centers - columns);
ind     = (one_off > 0 & one_off < 5);
out     = select(data(:,:,ind), one_off(ind));