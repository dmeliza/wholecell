function [] = TimeCourseWizard(matfile, mode)
%
% Loads the timecourse data from each cell in an AutoAnalyze matfile and
% yadda yadda I HATE STATISTICS.
%
% $Id$
warning off MATLAB:divideByZero
FIRST   = 'pre';
LAST    = 'pst';
FIELD   = 'ampl';
BIN     = 1;    % minutes
LTP_WINDOW   = [0.1 40];
LTD_WINDOW   = [-65 -0.1]; 
BEFORE       = [-12.1 -2];    % minutes, inclusive to use for pre-induction measures
AFTER        = [-.1 15.1];
CUTOFF       = [-1.5];          % splits before and after
MINAMPL      = 10;

error(nargchk(1,2,nargin))
if nargin < 2
    mode    = '';
end

Z   = load(matfile);
if ~isfield(Z,'results')
    error('Matfile must contain a results field.')
end
Z   = Z.results;

% extract some parameters that we'll use later. Note that t_onset is for
% the center response, while t_peak is for the conditioned response
cells   = length(Z);
conds   = length(Z(1).pre);
t_spike = [Z.t_spike];
x_spike = [Z.induced];

% what we need to do here is create a vector with ALL the response data in
% it, but with accompanying index vectors that will let us extract time,
% etc.  To make life easier, we're going to bin stuff down first.
% Here is all the bullshit we need to keep track of:
NAMES = {Z.rat;Z.cell}';
AMPL    = [];
TIME    = [];
DELTA   = [];       % delta t
POS     = [];       % absolute position
CENT    = [];       % relative to x_center
INDUCE  = [];       % x_spike;
EXPT    = [];       % an index to the xperiment
VALID   = [];       % 0 or 1, used to exclude events that are too small
for i = 1:cells
    fprintf('\n%s/%s',Z(i).rat, Z(i).cell);
    % detect center
    for j = 1:length(Z(i).(FIRST))
        mn(j)   = mean(Z(i).(FIRST)(j).(FIELD));
    end
    [m,x_center(i)] = max(mn);    
    % reject cell if < cutoff
    fprintf(' (%3.3f pA)', m);
    if m < MINAMPL
        fprintf(' - reject');
        valid       = 0;
    else
        valid       = 1;
    end
    t_peak(i)       = Z(i).(FIRST)(x_spike(i)).t_peak;

    % adjust sweep times
    at_start        = datenum(Z(i).pst(x_spike(i)).start);
    delta           = (t_spike(i) - t_peak(i)) * 1000;
    induce          = x_spike(i);
    expt            = i;

    for j = 1:length(Z(i).(FIRST))
        pos         = j;
        cent        = x_center(i);
        [t, a]      = gettimecourse(Z(i).(FIRST)(j), at_start, FIELD, BIN);
        AMPL        = cat(1,AMPL,a);
        TIME        = cat(1,TIME,t);
        
        DELTA       = cat(1,DELTA,repmat(delta,size(a)));
        POS         = cat(1,POS,repmat(pos,size(a)));
        CENT        = cat(1,CENT,repmat(cent,size(a)));
        INDUCE      = cat(1,INDUCE,repmat(induce,size(a)));
        EXPT        = cat(1,EXPT,repmat(expt,size(a)));
        VALID       = cat(1,VALID,repmat(valid,size(a)));
    end
    for j = 1:length(Z(i).(LAST))
        pos         = j;
        cent        = x_center(i);
        [t, a]      = gettimecourse(Z(i).(LAST)(j), at_start, FIELD, BIN);
        AMPL        = cat(1,AMPL,a);
        TIME        = cat(1,TIME,t);
        
        DELTA       = cat(1,DELTA,repmat(delta,size(a)));
        POS         = cat(1,POS,repmat(pos,size(a)));
        CENT        = cat(1,CENT,repmat(cent,size(a)));
        INDUCE      = cat(1,INDUCE,repmat(induce,size(a)));
        EXPT        = cat(1,EXPT,repmat(expt,size(a)));
        VALID       = cat(1,VALID,repmat(valid,size(a)));
        end
    end
end
fprintf('\n');

% we can normalize in two ways, either by experiment, or by condition
before   = TIME >= BEFORE(1) & TIME <= BEFORE(2);
after    = TIME >= AFTER(1) & TIME <= AFTER(2);
for i = 1:cells
    expt    = EXPT == i;
    baseln  = POS == x_center(i) & before;
    mu      = mean(AMPL(expt & baseln));
    RF(expt) = AMPL(expt) / mu;
    
    for j = 1:conds
        cond    = POS == j;
        baseln  = before;
        mu      = mean(AMPL(expt & cond & baseln));
        if ~isnan(mu)
            NORMAMPL(expt & cond) = AMPL(expt & cond) / mu;
        else
            NORMAMPL(expt & cond) = NaN;
        end
    end
end

% first order of business - time course for induced conditions, LTP and LTD
induced  = INDUCE == POS;
ltp_ind  = DELTA > LTP_WINDOW(1) & DELTA < LTP_WINDOW(2) & VALID; 
ltd_ind  = DELTA > LTD_WINDOW(1) & DELTA < LTD_WINDOW(2) & VALID; 


figure
% collect by time and plot timecourse`
subplot(3,3,1)
[t,d,e]     = collect(NORMAMPL, TIME, induced & (before | after) & ltp_ind);
errorbar(t, d, e, 'bo');
hold on
[t,d,e] = collect(NORMAMPL, TIME, induced & (before | after) & ltd_ind);
errorbar(t, d, e, 'ro');
axis tight

% compute confidence intervals based on cells as indep observations
subplot(3,3,4)
[c,pre,e]   = collect(NORMAMPL, EXPT, induced & (before) & ltp_ind);
[c,pst,e]   = collect(NORMAMPL, EXPT, induced & (after) & ltp_ind);
[ltp_m, ltp_ci, ltp_p]     = getdifference(pre, pst);
[c,pre,e]   = collect(NORMAMPL, EXPT, induced & (before) & ltd_ind);
[c,pst,e]   = collect(NORMAMPL, EXPT, induced & (after) & ltd_ind);
[ltd_m, ltd_ci, ltd_p]     = getdifference(pre, pst);
whiskerbar(0:1, [ltp_m ltd_m], [ltp_ci(1) ltd_ci(1)], [ltp_ci(2) ltd_ci(2)]);
set(gca,'xticklabel',{'LTP','LTD'})
axis tight

% now the four experimental conditions
% surround/LTP:
surround    = abs(INDUCE - CENT) > 0 & abs(INDUCE - CENT) < 3;
center      = abs(INDUCE - CENT) == 0;
position    = abs(POS - CENT);

subplot(3,3,2)
ind         = surround & ltp_ind & (before | after);
%[mu, ci, p] = getpositions(NORMAMPL, TIME, EXPT, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
[expt, m_induced, p_induced] = collectcompare(NORMAMPL, EXPT,...
    ind & induced & before, ind & induced & after);
[expt, m_nonind, p_nonind] = collectcompare(NORMAMPL, EXPT,...
    ind & position==0 & before, ind & position==0 & after);
whiskerbar(1:2, [mean(m_induced) mean(m_nonind)],...
    [std(m_induced)/sqrt(length(m_induced)) std(m_nonind)/sqrt(length(m_nonind))]);
set(gca,'xticklabel',{'Flank','Peak'});
axis tight
ylabel('Surround')
title(sprintf('\\Deltat>0 n=%d',length(m_nonind)))

subplot(3,3,3)
ind         = surround & ltd_ind & (before | after);
%[mu, ci, p] = getpositions(NORMAMPL, TIME, EXPT, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
[expt, m_induced, p_induced] = collectcompare(NORMAMPL, EXPT,...
    ind & induced & before, ind & induced & after);
[expt, m_nonind, p_nonind] = collectcompare(NORMAMPL, EXPT,...
    ind & position==0 & before, ind & position==0 & after);
whiskerbar(1:2, [mean(m_induced) mean(m_nonind)],...
    [std(m_induced)/sqrt(length(m_induced)) std(m_nonind)/sqrt(length(m_nonind))]);
set(gca,'xticklabel',{'Flank','Peak'});
axis tight
title(sprintf('\\Deltat<0 n=%d',length(m_nonind)))

subplot(3,3,5)
ind         = center & ltp_ind & (before | after);
%[mu, ci, p] = getpositions(NORMAMPL, TIME, EXPT, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
[expt, m_induced, p_induced] = collectcompare(NORMAMPL, EXPT,...
    ind & position==0 & before, ind & position==0 & after);
[expt, m_ninduced1, p_ninduced1] = collectcompare(NORMAMPL, EXPT,...
    ind & position==1 & before, ind & position==1 & after);
[expt, m_ninduced2, p_ninduced2] = collectcompare(NORMAMPL, EXPT,...
    ind & position==2 & before, ind & position==2 & after);
whiskerbar(1:3, [mean(m_induced) mean(m_ninduced1) mean(m_ninduced2)],...
    [std(m_induced)/sqrt(length(m_induced)),...
        std(m_ninduced1)/sqrt(length(m_ninduced1)),...
        std(m_ninduced2)/sqrt(length(m_ninduced2))]);
set(gca,'xticklabel',{'Peak','Flank1','Flank2'});
axis tight
ylabel('Center')
title(sprintf('n=%d',length(m_induced)));

subplot(3,3,6)
ind         = center & ltd_ind & (before | after);
%[mu, ci, p] = getpositions(NORMAMPL, TIME, EXPT, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
[expt, m_induced, p_induced] = collectcompare(NORMAMPL, EXPT,...
    ind & position==0 & before, ind & position==0 & after);
[expt, m_ninduced1, p_ninduced1] = collectcompare(NORMAMPL, EXPT,...
    ind & position==1 & before, ind & position==1 & after);
[expt, m_ninduced2, p_ninduced2] = collectcompare(NORMAMPL, EXPT,...
    ind & position==2 & before, ind & position==2 & after);
whiskerbar(1:3, [mean(m_induced) mean(m_ninduced1) mean(m_ninduced2)],...
    [std(m_induced)/sqrt(length(m_induced)),...
        std(m_ninduced1)/sqrt(length(m_ninduced1)),...
        std(m_ninduced2)/sqrt(length(m_ninduced2))]);
set(gca,'xticklabel',{'Peak','Flank1','Flank2'});
axis tight
title(sprintf('n=%d',length(m_induced)));

% % okay, here's another (pointless idea)
% % surround:
% surround_cells = find(abs(x_spike - x_center) == 1);
% delta          = (t_spike(surround_cells) - t_peak(surround_cells))';
% for i = 1:length(surround_cells)
%     ind     = surround & (before | after) & EXPT==surround_cells(i) & induced;
%     d       = NORMAMPL(ind);
%     t       = TIME(ind);
%     plast_induced(i,:)   = getdifference(d(t<CUTOFF), d(t>CUTOFF));
%     ind     = surround & (before | after) & EXPT==surround_cells(i) & POS==CENT;
%     d       = NORMAMPL(ind);
%     t       = TIME(ind);
%     plast_nonind(i,:)    = getdifference(d(t<CUTOFF), d(t>CUTOFF));
% end

function [mu, ci, p] = getpositions(RF, TIME, EXPT, index, position, CUTOFF)
colorscheme = {'bo','ro','go','ko'};
pos_uniq    = unique(position);
for i = 1:length(pos_uniq)
    ind         = index & position==pos_uniq(i);
    if sum(ind) > 0
        [t,d,e]     = collect(RF, TIME, ind);
        errorbar(t,d,e,colorscheme{i});
        hold on
        [mu(i,:), ci(i,:), p(i)]  = getdifference(d(t<CUTOFF), d(t>CUTOFF));
    else
        mu(i,:) = 0;
        ci(i,:) = 0;
        p(i)    = 0;
    end
end

function [t, d, p] = collectcompare(data, selector, index1, index2)
% like collect(), but this time we compare two populations, specified by
% index1 and index2, and returns the difference (and a p value)
t   = unique(selector(index1 | index2));
for i = 1:length(t)
    ind =   selector == t(i);
    X   =   data(ind & index1);
    Y   =   data(ind & index2);
    d(i,:)      = nanmean(Y) - nanmean(X);
    [h,p(i,:)]  = ttest2(Y,X);
end
% remove NaN's from empty data sets
t   = t(~isnan(p));
d   = d(~isnan(p));
p   = p(~isnan(p));
    
function [t, d, e] = collect(data, selector, index)
% uses an indexing variable to sort data into groups. 
% if an indexing logical array is supplied, it will be applied first
if nargin > 2
    data    = data(index);
    selector   = selector(index);
end
t       = unique(selector);
for i = 1:length(t)
    ind     = selector == t(i);
    d(i,:)  = mean(data(ind));
    e(i,:)  = std(data(ind)) ./ sqrt(sum(ind));
end

function [d, ci, p] = getdifference(A, B)
[h, p, ci] = ttest2(B,A);
d          = mean(B) - mean(A);
ci         = ci - d;

function [t,a] = gettimecourse(Z, at_adjust, field, binwidth);
% returns empty arrays if no event was detected
at_adjust   = (at_adjust - datenum(Z.start))*1440;
if ~isempty(Z.(field))
    [t,a]       = TimeBin(Z.time - at_adjust, Z.(field), binwidth);
else
    [t,a]       = deal([]);
end
