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

z   = csvread(csvfile,0,1);
s   = size(z,2);
% if s > 2
%     z(:,2) = sum(z(:,2:end),2);
% end
pre     = z(:,1);
post    = z(:,2);
delay_o   = z(:,3);
delay_p   = z(:,4);
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
ltp_p   = signrank(pre(ltp_ind),post(ltp_ind))
ltd_p   = signrank(pre(ltd_ind),post(ltd_ind))

f   = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,SZ);



a   = axes;
h   = plot(delay,STDP .* 100,'ko');
%YLIM = [0,max(z(:,2))];
set(a,'XLim',[-WIDTH WIDTH],'YLim',YLIM)
hline(100,'r:')
vline(0,'r:')
xlabel('Pre/Postsynaptic Time Interval (ms)')
ylabel('Change in EPSC amplitude (%)')
%text(WIDTH * 0.6, YLIM(2) * 0.9, sprintf('(n = %d)',length(STDP)));