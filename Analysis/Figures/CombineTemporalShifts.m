function [] = CombineTemporalShifts(file)
%
% Generates the figure that shows how the temporal response
% of the cell to a bar of light shifts after induction.
%
%
% $Id$
USE = [1 2 3 4 6 7 8 9 10 11 12];
SZ  = [3.5 2.9];


z = load(file);

mn  = mean(z.af(:,USE),2);
st  = std(z.af(:,USE),0,2);
sem = st/sqrt(length(USE));

f   = figure;
set(f,'color',[1 1 1]);
set(f,'units','inches')
p   = get(f,'position');
p   = [p(1) p(2) SZ(1) SZ(2)];
set(f,'position',p);

a   = axes;
hold on;
% assume a sampling rate of 10 kHz
len = size(mn,1);
T   = linspace(-len/20,len/20,len);
p   = plot(T,mn,'k');
% set(p,'linewidth',3);
% p   = plot(T,mn+sem,'k:');
% p   = plot(T,mn-sem,'k:');
%errorbar(T,mn,st/length(USE))
axis tight
mx  = max(abs(mn));
set(a,'YLim',[-mx mx],'Box','On');
hline(0)
vline(0)
xlabel('Time from spike (ms)');
ylabel('Change in Response (Normalized)');
text(len/40,mx*.6,sprintf('(n = %d)',length(USE)));