function [] = ExampleCell(filename)
%
% Script to produce a nifty example cell figure
% Loads a mat file exported from episodeanalysis. Plots each variable in
% its own axes. Leaves the first variable unbinned but bins the others
% to one minute.

% $Id$
BINSIZE = 1;
V_STEP  = 5; % mV
I_STEP  = 0.3; % nA
ZMAX    = 1.5;

z = load(filename);
z = z.results;

f = figure;
set(f,'color',[1 1 1]);
set(f,'units','inches')
p   = get(f,'position');
p   = [p(1) p(2) 3.8 2.2];
set(f,'position',p);

nplot   = length(z);
p       = 3;
% p       = (nplot-1)*2;
% a       = subplot(p,1,[1:nplot-1]);
a       = subplot(p,1,[1:2]);
nplot   = 2;
hold on

% plot the response data first
for i = 1:length(z(1).results)
    t   = z(1).results(i).abstime;
    v   = z(1).results(i).value;
    h   = plot(t(v>0),v(v>0),'k.');
    set(h,'markersize',6)
    mn = mean(v(v>0));
    h = plot([t(1) t(end)],[mn mn],'r:');
    set(h,'linewidth',2)
end
set(a,'XTickLabel',[]);
ylabel(sprintf('EPSC Amplitude (%s)',z(1).results(i).units));

% now plot the ancillary data
for i = 2:length(z)
    nplot   = nplot+1;
    a  = subplot(p,1,nplot);
    hold on
    for j = 1:length(z(i).results)
        t               = z(i).results(j).abstime;
        v               = z(i).results(j).value;
        t               = t(v>0);
        v               = v(v>0);
        [t, v, n, stdv] = TimeBin(t, v, BINSIZE);
        switch lower(z(i).name)
            case {'ir', 'sr'}
                % convert current values into resistance
                % (V = IR)
                % note that the division operation can make a mess
                switch lower(z(i).results(j).units)
                    case 'pa'
                        v   = V_STEP ./ v * 1000;
                    case 'na'                
                        v  = V_STEP ./ v;
                    case 'mV'
                        v  = v ./ I_STEP;
                end
                % clean up noise
                Z   = zscore(v);
                Z   = abs(Z) <= ZMAX;
                t   = t(Z);
                v   = v(Z);
                z(i).results(j).units = 'M\Omega';  % TeX markup
        end
        h   = plot(t,v,'ko');
    end
    set(a,'XTickLabel',[])
    ylabel(sprintf('%s (%s)', z(i).name, z(i).results(j).units));
end
set(a,'XTickLabelMode','Auto')
xlabel('Time (min)')
ax      = findobj(f,'type','axes');
xt      = get(ax,'XTick');
len     = cellfun('length',xt);
[m,i]   = min(len);
xl      = get(ax(i),'XLim');
set(ax,'XLim',xl);
