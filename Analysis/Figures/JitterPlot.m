function [rp, t] = JitterPlot(daqfile, thresh)
%
% Plots several trials of an acquisition to demonstrate the 
% jitter in event timing.
%
% $Id$
SZ  = [2.7    6.5];
SCL = [100 10];
BR  = 100;
THRESH = 1.5;
NORM    = [];
TRIM    = 1;
WIN     = 1000:8000;

z   = load('-mat',daqfile);

f   = figure;
set(f,'units','inches','color',[1 1 1])
p   = get(f,'position');
set(f,'position',[p(1) p(2) SZ(1) SZ(2)]);
movegui('center')


d   = double(z.r0.data(1000:8000,:));
ind = randperm(size(d,2));
d   = bindata(d,BR,1);
if ~isempty(NORM)
    d   = d - repmat(mean(d(NORM,:),1),size(d,1),1);
end
t   = bindata(z.r0.time(1000:8000),BR,1) * 1000 - 200;

subplot(3,1,1)
if TRIM
    mx  = max(abs(d));
    d   = d(:,abs(zscore(mx))<4);
    fprintf('Excluded: %d\n',length(find(abs(zscore(mx))>=3)));
end
mtrialplot(t,d);
set(gca,'xtick',[],'ytick',[],'xcolor',[1 1 1],'ycolor',[1 1 1])
mx  = max(max(d));
mn  = min(min(d));
h   = plot([000 500],[mx + 10, mx + 10],'k');
set(h,'linewidth',3)
axis tight
xlim    = get(gca,'XLim');
xx      = xlim(1) + diff(xlim) * 0.7;
h1  = plot([xx xx+SCL(1)],[mn mn],'k');
h2  = plot([xx+SCL(1) xx+SCL(1)],[mn mn+SCL(2)],'k');
text(xx+5, mn - 10, sprintf('%d ms',SCL(1)));
text(xx+SCL(1)+10, mn + SCL(2)/2, sprintf('%d pA',SCL(2)));
set([h1 h2],'linewidth',2)
%set(gca,'YLim',[-160 30]);

subplot(3,1,2);
rp      = -Rasterify(d,THRESH);
p       = imagesc(t,1:size(rp,2),rp');
set(gca,'XTickLabel',[],'Box','On','XLim',xlim);
colormap(flipud(gray))
ylabel('Trial #')


subplot(3,1,3);
% rps     = sum(rp,2);
% rpc     = sum(rp>0,2);
% rpm     = rps ./ rpc;
rpm     = mean(rp,2);

plot(t,rpm,'k')
ylabel('Mean Event Size (pA)')
set(gca,'Xlim',xlim);
%
% t   = repmat(t,size(rp,2));
% i   = find(rp);
% scatter(t(i),rp(i),'k.')
% ylabel('Event Size (pA)')
% set(gca,'Box','On','YLim',[0 max(max(rp))])
%
xlabel('Time (ms)')

