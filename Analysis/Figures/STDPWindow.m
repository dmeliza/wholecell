function [STDP,delay,ltp_p,ltd_p] = STDPWindow(csvfile)
% STDPWINDOW - Plots the STDP window from the data in a csvfile.
%
% [STDP, dt, ltp_p, ltd_p] = STDPWindow(csvfile)
%
% returns the change in response (STDP) as a function of pairing interval (dt),
% and the P values for a significant change in response across the
% population over a fixed spike timing window (set in the mfile)
%
% csvfile is a comma-delimited file with the following fields:
%    rat/cell   pre   post  delay-onset   delay-peak
% 
% $Id$

% Analysis constants
LTD_WIN = [-60 -1];
LTP_WIN = [1 40];

% Display options
WIDTH   = 100;
YLIM    = [0 220];
SZ      = [3.5 2.9];
LEGEND  = 0;            % label each cell
XLABEL  = 'Pairing Interval (ms)';
YLABEL  = 'Normalized Response Amplitude (%)';
REVERSE = 1;            % if 1, the x-axis is reversed
FIT     = 0;            % if 1, try to fit each side of the graph with a single exp

[names, pre, post, delay_o, delay_p] = textread(csvfile,'%s%n%n%n%n%*[^\n]','delimiter',',');

delay     = delay_p;
STDP    = (post ./ pre) * 100;

% compute significance over windows
ltp_ind = delay >= LTP_WIN(1) & delay <= LTP_WIN(2);
ltd_ind = delay >= LTD_WIN(1) & delay <= LTD_WIN(2);
ltp_m   = mean(STDP(ltp_ind));
ltd_m   = mean(STDP(ltd_ind));
ltp_e   = std(STDP(ltp_ind))/sqrt(length(ltp_ind));
ltd_e   = std(STDP(ltd_ind))/sqrt(length(ltd_ind));
[h,ltp_p,ltp_ci,ltp_stats]   = ttest(STDP(ltp_ind),100);
[h,ltd_p,ltd_ci,ltd_stats]   = ttest(STDP(ltd_ind),100);

fprintf('LTP (dt = %d to %d): %3.2f %s %3.2f (n = %d, P = %3.3f)\n',...
    LTP_WIN(1), LTP_WIN(2), ltp_m, char(177), ltp_e, length(ltp_ind), ltp_p);
fprintf('LTD (dt = %d to %d): %3.2f %s %3.2f (n = %d, P = %3.3f)\n',...
    LTD_WIN(1), LTD_WIN(2), ltd_m, char(177), ltd_e, length(ltd_ind), ltd_p);

% Plot results
f   = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,SZ);

h   = plot(delay,STDP,'ko');
if LEGEND
    h   = text(delay, STDP, names);
end
set(gca,'XLim',[-WIDTH WIDTH],'YLim',YLIM)
hline(100,'r:')
vline(0,'r:')
xlabel(XLABEL)
ylabel(YLABEL)
if REVERSE
    set(gca,'XDir','reverse');
end

if FIT
    % LTP
    select   = delay > 0;
    X   = delay(select);
    Y   = STDP(select) - 100;
    [p_coefs, model, Rsq, P, ci] = ExpDecayFit(X, Y);
    fprintf('LTP fit: A+ = %3.2f%%, t+ = %3.2f ms (P = %4.4f)\n',...
        p_coefs(1), p_coefs(2), P);
    % LTD
    select  = delay < 0;
    X   = delay(select);
    Y   = STDP(select) - 100;
    [d_coefs, model, Rsq, P, ci] = ExpDecayFit(X, Y);
    fprintf('LTD fit: A+ = %3.2f%%, t+ = %3.2f ms (P = %4.4f)\n',...
        d_coefs(1), d_coefs(2), P);
    % plot
    expr    = [char(model) ' + 100'];
    fun     = inline(expr,'x','b');
    hold on
    fplot(fun,[0 WIDTH],[],[],[],p_coefs);
    fplot(fun,[-WIDTH 0],[],[],[],d_coefs);
    set(gca,'xlim',[-WIDTH WIDTH]);
end
    