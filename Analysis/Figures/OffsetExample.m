function [xc_pre,xc_pst,xc_t] = OffsetExample(pre_r0, post_r0, spike_r0, t_light, t_response)
% Script for analyzing offset responses. These were not directly paired,
% but did have spontaneous activity that could have altered the response.
% This script does most of the analysis itself; the user just points it to
% the relevant .r0 files.
%
% OffsetExample(pre-r0, post-r0, spike-r0, t_light, t_response)
% PRE-R0, POST-R0, and SPIKE-R0 are files that contain the traces for
% pre-induction, post-induction, and induction. T_LIGHT is the time of the
% light turning off. T_SPIKE is a 2x1 array of the times between which to
% calculate the response. The OFF response is frequently more complex than
% the ON response, so the response is going to be the integral

% $Id$

LENGTH  = 0.7;
LPFILT  = 500;

FIGURE  = [5.0 3.9];
FIELD   = 'results';
XLABEL  = 'Time (min)';
YLABEL  = 'Response Amplitude (%s)';
START   = 200;          % start time of plot, ms
WIN     = [-10 510];    % length of plot (rel to START)
LIGHT   = [0 500];      % time when bar of light is on (rel to START)

error(nargchk(5,5,nargin))

% Load the data
A   = LoadResponseFile(pre_r0);
% A   = A.r0;
B   = LoadResponseFile(post_r0);
% B   = B.r0;
S   = LoadResponseFile(spike_r0);
% S   = S.r0;

% Extract the traces
[tr_pre, tr_t]  = gettraces(A, t_light,LENGTH, LPFILT);
[tr_pst]        = gettraces(B, t_light,LENGTH, LPFILT);
[tr_spk]        = gettraces(S, t_light,LENGTH);

% The plot is very simple. On top, a plot of the pre and post induction
% traces. In the middle, a mtrialplot of the induction period. On the
% bottom, the time course of the response.

% First figure out median spike time
% Run AutoAnalyzeSpikeTiming to get the spike times
[pn fn] = fileparts(spike_r0);
[med, var, n, sptimes] = AutoAnalyzeSpikeTiming(pn);
sptimes = sptimes + 0.2;
sptimes = sptimes(sptimes > tr_t(1) & sptimes < tr_t(end));
% spike times have been pre-corrected for light ON, recorrect
spmed   = (median(sptimes) - t_light) * 1000;

f   = figure;
ResizeFigure(FIGURE);
set(f,'Name',pre_r0);

% Top plot
ax(1)  = subplot(3,1,1);
T   = (tr_t - t_light) * 1000;
X   = mean(tr_pre,2);
Y   = mean(tr_pst,2);
ind_n  = tr_t < t_response(1);
X_n = mean(X(ind_n));
Y_n = mean(Y(ind_n));
% plot(T, X - X_n, 'k',...
%     T,Y - Y_n, 'r');
plot(T, X - X_n, 'k');
ylabel('Response (pA)')
axis tight
% vline(spmed)
% vline((t_response - t_light) * 1000,'k:')


% Middle plot
ax(2)   = subplot(3,1,2);
mtrialplot(T, tr_spk)
ylabel('Response (mV)')
xlabel('Time (ms)')
axis tight


% xcorr of the pre-induction response vs the post-induction response
% condition the pre by making it zero-mean
X       =  mean(X) - X;
X       =  X ./ max(X);
Y       = mean(Y) - Y;
Y       = Y ./ max(Y);
[t_xc pre]  = TimeBin(T, X, 1);
[t_xc pst]  = TimeBin(T, Y, 1);
% turn the spike train into a histogram
spt     = (sptimes - t_light) * 1000;
supr    = histc(spt,t_xc);
xc_pre  = xcorr(supr,pre);
xc_pst  = xcorr(supr,pst);
xc_t    = linspace(-t_xc(end),t_xc(end),length(xc_pre));
ax(3)   = subplot(3,1,3);
plot(xc_t,xc_pre,'k',xc_t,xc_pst,'r');

fprintf('Spike rate: %3.2f\n', length(sptimes)/size(tr_spk,2));
% keyboard

% % Bottom plot
% % Response is defined as the difference between the mean value of the
% % response (between t_response's values) and the baseline (between t_light
% % and t_response(1))
% ind_r   = tr_t > t_response(1) & tr_t < t_response(2);
% pre_n   = tr_pre(ind_n,:);
% pre_r   = tr_pre(ind_r,:);
% pre     = -(mean(pre_r) - mean(pre_n));
% 
% pst_n   = tr_pst(ind_n,:);
% pst_r   = tr_pst(ind_r,:);
% pst     = -(mean(pst_r) - mean(pst_n));
% 
% pre_mn  = mean(pre);
% pst_mn  = mean(pst);
% pre_se  = std(pre)/sqrt(length(pre));
% pst_se  = std(pst)/sqrt(length(pst));
% d_resp  = pst_mn / pre_mn * 100 - 100;
% 
% fprintf('%3.2f±%3.2f » %3.2f±%3.2f (%3.2f%%)\n',...
%     pre_mn, pre_se, pst_mn, pst_se, d_resp);
% 
% ax(3)   = subplot(3,1,3);
% pre_at  = A.abstime;
% pst_at  = B.abstime + pre_at(end) + 5;
% plot(pre_at, pre, 'k.', pst_at, pst, 'k.');
% hline(pre_mn)
% ylabel('Response (pA)')
% xlabel('Time (min)')
% axis tight
% keyboard

function [trace, time] = gettraces(r0, t_start, LENGTH, LPFILT)
ind_trace   = r0.time > t_start & r0.time < t_start + LENGTH;
trace   = r0.data(ind_trace,:);
time    = r0.time(ind_trace);
if nargin > 3
    Fs      = 1/mean(diff(time));
    trace   = filterresponse(trace, LPFILT, 3, Fs);
end

function out = filterresponse(data, cutoff, order, Fs)
data     = NotchFilter(data, 60, Fs, 20);
Wn      = double(cutoff/(Fs/2));
if Wn >= 1
    Wn = 0.999;
end
[b,a]   = butter(order,Wn);
out     = filtfilt(b,a,data);