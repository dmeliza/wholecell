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
LEGEND  = 1;            % label each cell

% use textread so we can get the names of the experiments
%textread(file,'%s%*[^\n]','delimiter',',')
[names, pre, post, delay_o, delay_p] = textread(csvfile,'%s%n%n%n%n%*[^\n]','delimiter',',')

delay     = delay_p;
switch mode
    case 'add'
        STDP    = (post - pre) ./ pre + 1
    otherwise
        STDP    = post ./ pre
end

% compute significance over windows
ltp_ind = find(delay >= LTP_WIN(1) & delay <= LTP_WIN(2));
ltd_ind = find(delay >= LTD_WIN(1) & delay <= LTD_WIN(2));
%ltp_p   = signrank(pre(ltp_ind),post(ltp_ind))
%ltd_p   = signrank(pre(ltd_ind),post(ltd_ind))
ltp_p   = ttest2(pre(ltp_ind),post(ltp_ind))
ltd_p   = ttest2(pre(ltd_ind),post(ltd_ind))

f   = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,SZ);

%    div = repmat(' - ',length(STDP),1);
%    leg = [char(names) div num2str(STDP,'%3.2f')];
%    h   = gscatter(delay,STDP .* 100,1:length(delay),[],[],[],'off');
%    legend(h,leg);
STDP    = STDP .* 100;
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
