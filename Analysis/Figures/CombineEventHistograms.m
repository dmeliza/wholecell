function [d, t] = CombineEventHistograms(control)
%
% Combines event histograms into a single graph.
% Input is an excel control file with the following structure:
% prefile,postfile,spikedelay\n ...

WINDOW = 150;       % ms
SZ      = [3.5 2.9];

[spikes, ctl]   = xlsread(control);

for i = 1:length(spikes)
    [dd(:,i), tt(:,i)] = CompareEvents(ctl{i,1}, ctl{i,2}, spikes(i));
end

Fs      = mean(diff(tt(:,1)));
T       = tt - repmat(spikes',size(tt,1),1);
[m,i]   = min(abs(T));              % i is the time index of the bin closest to the synch
W       = fix(WINDOW/Fs);
ind     = repmat([-W:W]',1,size(tt,2));
I       = ind + repmat(i,size(ind,1),1);
J       = repmat(1:size(tt,2),size(ind,1),1);
IJ      = sub2ind(size(tt),I,J);

d       = dd(IJ);
d       = mean(d,2);
t       = linspace(-WINDOW,WINDOW,size(d,1));
% d       = bindata(d,3,2);
% t       = bindata(t,3,2);

if nargout == 0
    f   = figure;
    set(f,'Color',[1 1 1],'Units','Inches')
    p   = get(f,'Position');
    set(f,'Position',[p(1) p(2) SZ(1) SZ(2)]);
    h   = plot(t,d,'k');
    xlabel('Time from spike (ms)')
    ylabel('Change in Event Amplitude')
    hline(0)
    vline(0)
end