function [] = RFWizard(matfile, mode)
%
%
% Lame name, but I'm too lazy to rename CompositeRF to something else.
% Basically this function loads in all the pre-induction RF's, synchronizes
% them to their start times, and produces a fancy composite RF.  Maybe if I
% get ambitious I will make it figure out some fun stats.
%
%
% $Id$

WINDOW  = [-1000 5000];   % in samples, analysis window (relative to onset)
FIRST   = 'pre';
EVENT_MIN   = 10.5;         % minimum size of the induced event (to avoid massive noise problems
NBOOT   = 1;
NORM    = 1;

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
t_spike = [Z.t_spike];
x_spike = [Z.induced];

warning off MATLAB:divideByZero
for i = 1:cells
    t_adjust    = datenum(Z(i).pst(x_spike(i)).start) - datenum(Z(i).pre(x_spike(i)).start);
    PRE{i}  = Z(i).pre(x_spike(i)).ampl;
    PRE_T{i}= Z(i).pre(x_spike(i)).time- t_adjust*1440;
    PST{i}  = Z(i).pst(x_spike(i)).ampl;
    PST_T{i}= Z(i).pst(x_spike(i)).time;
    for j = 1:length(Z(i).(FIRST))
        mn(j)   = mean(Z(i).(FIRST)(j).ampl);
    end
    [m,x_center(i)] = max(mn);
    t_onset(i)      = Z(i).(FIRST)(x_center(i)).t_onset;
    t_peak(i)       = Z(i).(FIRST)(x_spike(i)).t_peak;
    t_peak_post(i)  = Z(i).pst(x_spike(i)).t_peak;
    mn_pre(i)       = mn(x_spike(i));
end
warning on MATLAB:divideByZero

% selectors
ind_clean = mn_pre > EVENT_MIN;
ind_ltp  = t_spike > t_peak & ind_clean;
ind_ltd  = t_spike < t_peak & ind_clean;
ind_center = x_center == x_spike & ind_clean;
ind_surround = abs(x_center - x_spike) == 1 & ind_clean;

% stuck in here because it's not worth writing a whole new script
delta    = (t_spike - t_peak)'*1000;
latency_shift = (t_peak_post - t_peak)'*1000;
mn_shift = mean(latency_shift(delta>0));
se_shift = std(latency_shift(delta>0)) ./ sqrt(sum(delta>0));

[rf_pre,rf_pst,t,INDEX]  = combine(Z(ind_clean), t_onset(ind_clean),...
                                   x_center(ind_clean), WINDOW, NORM);
rf_pre       = collapse(rf_pre,2);
rf_pst       = collapse(rf_pst,2);

figure
ResizeFigure(gcf,[2.66, 1.41]);
plot(t,rf_pre);
axis tight
legend({'peak','1','2','3'});
legend boxoff
addscalebar(gca,{'ms',''},[50 0]);

figure
subplot(3,3,1)

title('Grand Mean RF (pre)');

% ind     = ind_surround;
% compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);
% title('LTP/LTD');


subplot(3,3,2)
ind     = ind_surround & ind_ltp;
compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);
ylabel('Condition Surround');
title('LTP');

subplot(3,3,3)
ind     = ind_surround & ind_ltd;
compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);
title('LTD');

% subplot(3,3,4)
% ind     = ind_center;
% compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);


subplot(3,3,5)
ind     = ind_center & ind_ltp;
compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);
ylabel('Condition Center');

subplot(3,3,6)
ind     = ind_center & ind_ltd;
compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);

% subplot(3,3,7)
% compare(Z,t_onset, x_center, WINDOW, 1:length(x_center), NBOOT);
% ylabel('All locations');
% 
% subplot(3,3,8)
% ind     = ind_ltp;
% compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);
% xlabel('Time From Spike (ms)')
% 
% subplot(3,3,9)
% ind     = ind_ltd;
% compare(Z,t_onset, x_center, WINDOW, ind, NBOOT);
    

function [mu] = compare(Z, t_onset, x_center, WINDOW, index, NBOOT)
[pre, pst, t, INDEX] = combine(Z(index),t_onset(index), x_center(index), WINDOW, 1);
if NBOOT == 1
    pre       = collapse(pre,2);
    pst       = collapse(pst,2);
    mu        = getdelta(pre, pst, t);
    bar(0:3,mu);
    %plot(0:3,mu);
%     d         = pre - pst;
%     plot(t,d(:,1:4));
else
    nexp    = length(find(index));
    for i=1:NBOOT
        sample  = unidrnd(nexp, 1, nexp);
        pre_rf  = collapse(pre, 2, sample, INDEX);
        pst_rf  = collapse(pst, 2, sample, INDEX);
        mu(i,:) = getdelta(pre_rf, pst_rf, t);
    end
    sigma    = std(mu,[],1);
    mu       = mean(mu,1);
    errorbar(0:3,mu,sigma);
end
    axis tight
    hline(0)
        

function [mu] = getdelta(pre, pst, t)
PLAST_WINDOW    = [0 100];
mx      = max(max(abs(pre)));
delta   = (pre-pst)./mx;
ind     = t >= PLAST_WINDOW(1) & t <= PLAST_WINDOW(2);
mu      = mean(delta(ind,:),1);

function [PRE_RF,PST_RF,t,INDEX] = combine(Z, t_onset, x_center, WINDOW, NORM)
% sorts the columns of each experiment into bins for the (absolute) distance 
% from x_center.
if nargin < 5
    NORM     = 0;
end
fieldname   = 'pre';
post    = 'pst';
ROWS    = length(Z(1).pre);
PRE_RF  = cell(ROWS,1);
PST_RF  = cell(ROWS,1);
cells   = length(Z);
INDEX   = cell(ROWS,1);
for i = 1:cells
    % figure out the normalization factor for the cell, not each exp!
    mx      = max(max(abs([Z(i).(fieldname).filttrace])));
    for j = 1:length(Z(i).(fieldname))
        J       = abs(j - x_center(i)) + 1;
        t       = (Z(i).(fieldname)(j).time_trace - t_onset(i)) * 1000;
        [m,I]   = min(abs(t));
        ind     = I+WINDOW(1):I+WINDOW(2);
        time    = t(ind);
        pre     = Z(i).(fieldname)(j).filttrace(ind);
        pst     = Z(i).(post)(j).filttrace(ind);
        % comment out this code to disable normalization
        if NORM
%            mx      = max(max(abs(pre)));
            pre     = pre ./ mx;
            pst     = pst ./ mx;
        end
        % we may also want to substract the two RFs from each other
        % immediately
        INDEX{J}    = cat(2,INDEX{J},i);
        PRE_RF{J}   = cat(2,PRE_RF{J},pre);   % this may break
        PST_RF{J}   = cat(2,PST_RF{J},pst);
    end
end
t   = time;

function [mu, sigma, n] = collapse(RF, dim, collapser, INDEX)
% collapses a cell array into a matrix along a given direction
% if INDEX and collapser are specified, then we pick out the entries
% corresponding to the indices in collapser.
for i = 1:length(RF)
    data         = RF{i};
    if nargin > 2
        weight   = MatchMatrix(collapser, INDEX{i});
        weight   = shiftdim(weight(:),dim-1);
        data     = data .* repmat(weight,size(data)./size(weight));
        wsum     = sum(weight);
        if wsum > 0
            mu(:,i)  = sum(data,dim) ./ wsum;
        else
            mu(:,i)  = sum(data,dim);
        end
    else
        mu(:,i)      = mean(data,dim);
    end
    n(:,i)       = size(data,dim);
    sigma(:,i)   = std(data,[],dim);% ./ sqrt(size(RF{i},2));
end
