function [] = ExampleCell(filename, start_time, end_time)
%
% Script to produce a nifty example cell figure
% Loads a mat file exported from episodeanalysis. Plots each variable in
% its own axes. Leaves the first variable unbinned but bins the others
% to one minute.
%
% ExampleCell(matfile, [start_time, [end_time]])
%
% specify start_time and end_time to control which points to include

% $Id$
BINSIZE = 1;
V_STEP  = 5; % mV
I_STEP  = 0.3; % nA
ZMAX    = 1.5;
RESPONSE_ONLY = 1;

if nargin < 3
    end_time = [];
end
if nargin < 2
    start_time = [];
end

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
offset = 0;
for i = 1:length(z(1).results)
    t   = z(1).results(i).abstime;
    v   = z(1).results(i).value;
    if i==1 & ~isempty(start_time)
        ind = find(t>=start_time);
        offset = t(ind(1));
        t   = t(ind);
        v   = v(ind);
    elseif i==length(z(1).results) & ~isempty(end_time)
        ind = find(t<=end_time);
        t   = t(ind);
        v   = v(ind);
    end
    t   = t - offset;
    h   = plot(t(v>0),v(v>0),'k.');
    set(h,'markersize',6)
    mn = mean(v(v>0));
    h = plot([t(1) t(end)],[mn mn],'r:');
    fprintf('Episode %d: %3.2f\n',i,mn);
    set(h,'linewidth',2)
end
if i > 1
    [H,P]   = ttest2(z(1).results(1).value, z(1).results(2).value);
    fprintf('p = %4.4f',P);
end

ylim    = get(gca,'YLim');
h   = plot(z(1).results(1).abstime(end) + 1, ylim(2) * 0.8,'kv');
set(h,'MarkerFaceColor',[0 0 0]);

ylabel(sprintf('EPSC Amplitude (%s)',z(1).results(i).units));

if RESPONSE_ONLY
    xlabel('Time (min)');    
    return
else
    set(a,'XTickLabel',[]);
end
    
% now plot the ancillary data
for i = 2:2 %length(z)
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
