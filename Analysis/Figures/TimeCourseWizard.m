function [] = TimeCourseWizard(matfile, mode)
%
% Loads the timecourse data from each cell in an AutoAnalyze matfile and
% yadda yadda I HATE STATISTICS.
%
% $Id$

FIRST   = 'pre';
LAST    = 'pst';
FIELD   = 'ampl';
BIN     = 1;    % minutes
LTP_WINDOW   = [0.1 40];
LTD_WINDOW   = [-65 -0.1]; 
BEFORE       = [-12.1 -2];    % minutes, inclusive to use for pre-induction measures
AFTER        = [-.1 15.1];
CUTOFF       = [-1.5];          % splits before and after

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
AMPL    = [];
TIME    = [];
DELTA   = [];       % delta t
POS     = [];       % absolute position
CENT    = [];       % relative to x_center
INDUCE  = [];       % x_spike;
EXPT    = [];       % just an index
for i = 1:cells
    fprintf('%s/%s\n',Z(i).rat, Z(i).cell);
    % detect center
    for j = 1:length(Z(i).(FIRST))
        mn(j)   = mean(Z(i).(FIRST)(j).(FIELD));
    end
    [m,x_center(i)] = max(mn);    
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
        end
    end
end

% we can normalize in two ways, either by experiment, or by condition
for i = 1:cells
    expt    = EXPT == i;
    baseln  = POS == x_center(i) & TIME < -1;
    mu      = mean(AMPL(expt & baseln));
    RF(expt) = AMPL(expt) / mu;
    
    for j = 1:conds
        cond    = POS == j;
        baseln  = TIME < -1;
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
before   = TIME >= BEFORE(1) & TIME <= BEFORE(2);
after    = TIME >= AFTER(1) & TIME <= AFTER(2);
ltp_ind  = DELTA > LTP_WINDOW(1) & DELTA < LTP_WINDOW(2); 
ltd_ind  = DELTA > LTD_WINDOW(1) & DELTA < LTD_WINDOW(2); 

figure
subplot(3,3,1)
[t,d,e] = timeify(NORMAMPL, TIME, induced & (before | after) & ltp_ind);
[ltp_m, ltp_ci, ltp_p]     = getdifference(d(t < CUTOFF), d(t > CUTOFF));
errorbar(t, d, e, 'bo');
hold on
[t,d,e] = timeify(NORMAMPL, TIME, induced & (before | after) & ltd_ind);
[ltd_m, ltd_ci, ltd_p]     = getdifference(d(t < CUTOFF), d(t > CUTOFF));
errorbar(t, d, e, 'ro');
axis tight

subplot(3,3,4)
whiskerbar(0:1, [ltp_m ltd_m], [ltp_ci(1) ltd_ci(1)], [ltp_ci(2) ltd_ci(2)]);
set(gca,'xticklabel',{'LTP','LTD'})
axis tight

% now the four experimental conditions
% surround/LTP:
surround    = abs(INDUCE - CENT) == 1;      % leaving out > 1 nows
center      = abs(INDUCE - CENT) == 0;
position    = abs(POS - CENT);

subplot(3,3,2)
ind         = surround & ltp_ind & (before | after);
[mu, ci, p] = getpositions(RF, TIME, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
axis tight
ylabel('Surround')
title('\Deltat>0')

subplot(3,3,3)
ind         = surround & ltd_ind & (before | after);
[mu, ci, p] = getpositions(RF, TIME, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
axis tight
title('\Deltat<0')

subplot(3,3,5)
ind         = center & ltp_ind & (before | after);
[mu, ci, p] = getpositions(RF, TIME, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
axis tight
ylabel('Center')

subplot(3,3,6)
ind         = center & ltd_ind & (before | after);
[mu, ci, p] = getpositions(RF, TIME, ind, position, CUTOFF);
%whiskerbar(1:conds, mu, ci(:,1), ci(:,2));
axis tight


function [mu, ci, p] = getpositions(RF, TIME, index, position, CUTOFF)
colorscheme = {'bo','ro','go','ko'};
pos_uniq    = unique(position);
for i = 1:length(pos_uniq)
    ind         = index & position==pos_uniq(i);
    if sum(ind) > 0
        [t,d,e]     = timeify(RF, TIME, ind);
        errorbar(t,d,e,colorscheme{i});
        hold on
        [mu(i,:), ci(i,:), p(i)]  = getdifference(d(t<CUTOFF), d(t>CUTOFF));
    else
        mu(i,:) = 0;
        ci(i,:) = 0;
        p(i)    = 0;
    end
end

function [t, d, e] = timeify(data, times, index)
% uses a time indexing variable to sort data into groups
% if an indexing logical array is supplied, it will be applied first
if nargin > 2
    data    = data(index);
    times   = times(index);
end
t       = unique(times);
for i = 1:length(t)
    ind     = times == t(i);
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
