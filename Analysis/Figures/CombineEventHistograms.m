function [d, t] = CombineEventHistograms(control, control2)
%
% Combines event histograms into a single graph.
% Input is an excel control file with the following structure:
% prefile,postfile,spikedelay\n ...
%
% CombineEventHistograms(control)
% CombineEventHistograms(control-LTP,control-LTD)
%
% If two control files are provided, the first one is used to generate the
% left half of the graph, and the second one for the right half of the
% graph
%
% $Id$

% $Id$

WINDOW = 150;       % ms
SZ      = [3.5 2.9];
BINSIZE = 5;
BINS    = [50];

[spikes, ctl]   = xlsread(control);
if nargin > 1
    [s2 ctl2]   = xlsread(control2);
    spikes      = cat(1,spikes,s2);
end
sz              = size(ctl,1);

for i = 1:length(spikes)
    if i <= sz
        [dd(:,i), tt(:,i)] = CompareEvents(ctl{i,1}, ctl{i,2}, spikes(i));
    else
        [dd(:,i), tt(:,i)] = CompareEvents(ctl2{i-sz,1}, ctl2{i-sz,2}, spikes(i));
    end
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
t       = linspace(-WINDOW,WINDOW,size(d,1));
if nargin == 1
    d       = mean(d,2);
else
    d_left  = mean(d(:,1:sz),2);
    d_right = mean(d(:,sz+1:end),2);
    d       = [d_left(t<0); d_right(t>=0)];
end
    
%d       = bindata(d,2,2);
%t       = bindata(t,2,2);

% try to fit each side to a single exponential
myfun   = inline('b(1) .* exp(x ./ b(2))','b','x');
zpt     = min(find(t>=0));
Xd      = t(zpt:end);
Yd      = d(zpt:end);
b0      = [mean(Yd(1:2)), -WINDOW/2];
beta_d  = nlinfit(Xd,Yd,myfun,b0)

Xp      = t(1:zpt-1);
Yp      = d(1:zpt-1);
b0      = [mean(Yp(end-2:end)) WINDOW/2];
beta_p  = nlinfit(Xp,Yp,myfun,b0)


if nargout == 0
    f   = figure;
    set(f,'Color',[1 1 1],'Units','Inches')
    p   = get(f,'Position');
    set(f,'Position',[p(1) p(2) SZ(1) SZ(2)]);
    h   = plot(t,d,'k');
    hold on
    plot(Xd,myfun(beta_d,Xd));
    plot(Xp,myfun(beta_p,Xp));
    xlabel('Time from spike (ms)')
    ylabel('Change in Event Amplitude')
    hline(0)
    vline(0)
end

