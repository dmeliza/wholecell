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
    for j = 1:length(Z(i).(FIRST))
        mn(j)   = mean(Z(i).(FIRST)(j).ampl);
    end
    [m,x_center(i)] = max(mn);
    t_onset(i)      = Z(i).(FIRST)(x_center(i)).t_onset;
    t_peak(i)       = Z(i).(FIRST)(x_spike(i)).t_peak;
    mn_pre(i)       = mn(x_spike(i));
end
warning on MATLAB:divideByZero

% selectors
ind_clean = mn_pre > EVENT_MIN;
ind_ltp  = t_spike > t_peak & ind_clean;
ind_ltd  = t_spike < t_peak & ind_clean;
ind_center = x_center == x_spike & ind_clean;
ind_surround = abs(x_center - x_spike) == 1 & ind_clean;

[rf_pre,rf_pst,rf_pre_e,rf_pst_e,t]  = combine(Z, t_onset, x_center, WINDOW);

subplot(3,3,1)
ind     = ind_surround;
compare(Z,t_onset, x_center, WINDOW, ind);
title('LTP/LTD');
ylabel('Condition Surround');

subplot(3,3,2)
ind     = ind_surround & ind_ltp;
compare(Z,t_onset, x_center, WINDOW, ind);
title('LTP');

subplot(3,3,3)
ind     = ind_surround & ind_ltd;
compare(Z,t_onset, x_center, WINDOW, ind);
title('LTD');

subplot(3,3,4)
ind     = ind_center;
compare(Z,t_onset, x_center, WINDOW, ind);
ylabel('Condition Center');

subplot(3,3,5)
ind     = ind_center & ind_ltp;
compare(Z,t_onset, x_center, WINDOW, ind);

subplot(3,3,6)
ind     = ind_center & ind_ltd;
compare(Z,t_onset, x_center, WINDOW, ind);

subplot(3,3,7)
compare(Z,t_onset, x_center, WINDOW, 1:length(x_center));
ylabel('All locations');

subplot(3,3,8)
ind     = ind_ltp;
compare(Z,t_onset, x_center, WINDOW, ind);
xlabel('Time From Spike (ms)')

subplot(3,3,9)
ind     = ind_ltd;
compare(Z,t_onset, x_center, WINDOW, ind);


function [mu] = compare(Z, t_onset, x_center, WINDOW, index)
PLAST_WINDOW    = [0 100];
[pre, pst, pre_e, pst_e, t] = combine(Z(index),t_onset(index), x_center(index), WINDOW);
mx      = max(max(abs(pre)));
delta   = (pre-pst)./mx;
ind     = t >= PLAST_WINDOW(1) & t <= PLAST_WINDOW(2);
mu      = mean(delta(ind,:),1);
bar([0:3],mu);
%plot(t, delta);
axis tight

function [rf_pre,rf_pst,rf_pre_sg,rf_pst_sg,t] = combine(Z, t_onset, x_center, WINDOW, NORM)
if nargin < 5
    NORM     = 0;
end
fieldname   = 'pre';
post    = 'pst';
ROWS    = length(Z(1).pre);
PRE_RF  = cell(ROWS,1);
PST_RF  = cell(ROWS,1);
cells   = length(Z);
for i = 1:cells
    for j = 1:length(Z(i).(fieldname))
        J       = abs(j - x_center(i)) + 1;
        t       = (Z(i).pre(j).time_trace - t_onset(i)) * 1000;
        [m,I]   = min(abs(t));
        ind     = I+WINDOW(1):I+WINDOW(2);
        time    = t(ind);
        pre     = Z(i).(fieldname)(j).filttrace(ind);
        pst     = Z(i).(post)(j).filttrace(ind);
        % comment out this code to disable normalization
        if NORM
            mx      = max(max(abs(pre)));
            pre     = pre ./ mx;
            pst     = pst ./ mx;
        end
        % we may also want to substract the two RFs from each other
        % immediately
        PRE_RF{J}   = cat(2,PRE_RF{J},pre);   % this may break
        PST_RF{J}   = cat(2,PST_RF{J},pst);
    end
end
% compute the grand mean RF
t   = time;
for i = 1:length(PRE_RF)
    rf_pre(:,i)      = mean(PRE_RF{i},2);
    rf_pre_sg(:,i)   = std(PRE_RF{i},[],2);% ./ sqrt(size(RF{i},2));
    rf_pst(:,i)      = mean(PST_RF{i},2);
    rf_pst_sg(:,i)   = std(PST_RF{i},[],2);% ./ sqrt(size(RF{i},2));
end
