function [] = STDPWindow(csvfile)
%
% Plots the STDP window in a csvfile
% If this is coming from prism we have to manipulate the post-induction
% values into a single column
%
% $Id$

WIDTH = 70;
YLIM  = [0 2];

z   = csvread(csvfile);
s   = size(z,2);
if s > 2
    z(:,2) = sum(z(:,2:end),2);
end
f   = figure;
set(f,'color',[1 1 1]);
set(f,'units','inches')
p   = get(f,'position');
p   = [p(1) p(2) 3.5 2.9];
set(f,'position',p);

a   = axes;
h   = plot(z(:,1),z(:,2),'ko');
%YLIM = [0,max(z(:,2))];
set(a,'XLim',[-WIDTH WIDTH],'YLim',YLIM)
hline(1)
vline(0)
xlabel('Pre/Postsynaptic Time Interval (ms)')
ylabel('Normalized EPSC Amplitude')