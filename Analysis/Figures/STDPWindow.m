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
LEGEND  = 0;            % label each cell

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

%    div = repmat(' - ',length(STDP),1);
%    leg = [char(names) div num2str(STDP,'%3.2f')];
%    h   = gscatter(delay,STDP .* 100,1:length(delay),[],[],[],'off');
%    legend(h,leg);
h   = plot(delay,STDP,'ko');
if LEGEND
    h   = text(delay, STDP, names);
end
%YLIM = [0,max(z(:,2))];
set(gca,'XLim',[-WIDTH WIDTH],'YLim',YLIM)
hline(100,'r:')
vline(0,'r:')
xlabel('Pre/Postsynaptic Time Interval (ms)')
ylabel('Change in EPSC amplitude (%)')
%text(WIDTH * 0.6, YLIM(2) * 0.9, sprintf('(n = %d)',length(STDP)));
