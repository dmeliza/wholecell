function [STDP,ltp_p,ltd_p] = STDPWindow(csvfile)
%
% Plots the STDP window in a csvfile
% If this is coming from prism we have to manipulate the post-induction
% values into a single column
%
% 1.3: uses csv file with the following fields:
%    rat/cell   pre   post  delay-onset   delay-peak
% 
% $Id$

WIDTH   = 100;
YLIM    = [0 220];
SZ      = [3.5 2.9];
mode    = 'add';
LTD_WIN = [-60 -1];
LTP_WIN = [1 40];
LEGEND  = 0;            % label each cell\
XLABEL  = 'Pre/post synaptic activity interval (ms)';
YLABEL  = 'Normalized EPSC amplitude (%)';
FIT     = 0;            % if 1, try to fit each side of the graph with a single exp

% use textread so we can get the names of the experiments
%textread(file,'%s%*[^\n]','delimiter',',')
[names, pre, post, delay_o, delay_p] = textread(csvfile,'%s%n%n%n%n%*[^\n]','delimiter',',');

delay     = delay_p;
switch mode
    case 'add'
        STDP    = (post - pre) ./ pre + 1;
    otherwise
        STDP    = post ./ pre;
end
STDP    = STDP .* 100;

% compute significance over windows
ltp_ind = find(delay >= LTP_WIN(1) & delay <= LTP_WIN(2));
ltd_ind = find(delay >= LTD_WIN(1) & delay <= LTD_WIN(2));
ltp_m   = mean(STDP(ltp_ind));
ltd_m   = mean(STDP(ltd_ind));
ltp_e   = std(STDP(ltp_ind))/sqrt(length(ltp_ind));
ltd_e   = std(STDP(ltd_ind))/sqrt(length(ltd_ind));
%ltp_p   = signrank(pre(ltp_ind),post(ltp_ind))
%ltd_p   = signrank(pre(ltd_ind),post(ltd_ind))
%[h, ltp_p]   = ttest(pre(ltp_ind) - post(ltp_ind));
%[h, ltd_p]   = ttest(pre(ltd_ind) - post(ltd_ind));
[h,ltp_p]   = ttest(STDP(ltp_ind),100);
[h,ltd_p]   = ttest(STDP(ltd_ind),100);

fprintf('LTP (dt = %d to %d): %3.2f %s %3.2f (P = %3.3f)\n',...
    LTP_WIN(1), LTP_WIN(2), ltp_m, char(177), ltp_e, ltp_p);
fprintf('LTD (dt = %d to %d): %3.2f %s %3.2f (P = %3.3f)\n',...
    LTD_WIN(1), LTD_WIN(2), ltd_m, char(177), ltd_e, ltd_p);

f   = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,SZ);

h   = plot(delay,STDP,'ko');
if LEGEND
    h   = text(delay, STDP, names);
end
%YLIM = [0,max(z(:,2))];
set(gca,'XLim',[-WIDTH WIDTH],'YLim',YLIM)
hline(100,'r:')
vline(0,'r:')
xlabel(XLABEL)
ylabel(YLABEL)
%text(WIDTH * 0.6, YLIM(2) * 0.9, sprintf('(n = %d)',length(STDP)));

if FIT
    expr    = '100 + b(1) * exp(-abs(x)/b(2))';
    % LTP
    XY      = [delay(delay > 0), STDP(delay > 0)];
    XY      = sortrows(XY);
    beta0   = [ltp_m, LTP_WIN(2)];  % guess
    fun     = inline(expr,'b','x');
    betaP   = nlinfit(XY(:,1), XY(:,2), fun, beta0);
    fprintf('LTP fit: A+ = %3.2f%%, t+ = %3.2f ms\n', betaP(1)+100, betaP(2));
    % LTD
    XY      = [delay(delay < 0), STDP(delay < 0)];
    XY      = sortrows(XY);
    beta0   = [ltd_m, abs(LTD_WIN(1))];  % guess
    betaD   = nlinfit(XY(:,1), XY(:,2), fun, beta0);
    fprintf('LTD fit: A- = %3.2f%%, t- = %3.2f ms\n', betaD(1)+100, betaD(2));
    % plot
    fun     = inline(expr,'x','b');
    hold on
    fplot(fun,[0 WIDTH],[],[],[],betaP);
    fplot(fun,[-WIDTH 0],[],[],[],betaD);
    set(gca,'xlim',[-WIDTH WIDTH]);
end
    