function [rp, t] = JitterPlotElec(daqfile, thresh)
%
% Plots several trials of an acquisition to demonstrate the 
% jitter in event timing.  Tuned for electrical acquisitions
%
% $Id$
SZ  = [2.7    6.5];
BR  = 20;
THRESH = 1.5;
NORM    = [];
WIN     = 1700:2700;

z   = load('-mat',daqfile);

f   = figure;
set(f,'units','inches','color',[1 1 1])
p   = get(f,'position');
set(f,'position',[p(1) p(2) SZ(1) SZ(2)]);
movegui('center')


d   = double(z.r0.data(WIN,:));
t   = double(z.r0.time(WIN,:)) * 1000 - 200;
t   = bindata(t,BR,1);
d   = bindata(d,BR,1);
if ~isempty(NORM)
    d   = d - repmat(mean(d(NORM,:),1),size(d,1),1);
end


subplot(3,1,1)
tt  = t(t<-2);
dd  = d(t<-2,:);
mtrialplot(tt,dd);hold on;
tt  = t(t>2);
dd  = d(t>2,:);
mtrialplot(tt,dd);
set(gca,'xtick',[],'ytick',[],'xcolor',[1 1 1],'ycolor',[1 1 1])
mx  = max(max(d(t<-2|t>2,:)));
mn  = min(min(d(t<-2|t>2,:)));
df  = mx - mn;
h   = plot(0,mx+(df*.1),'kv');
set(h,'MarkerFaceColor',[0 0 0]);
% h   = plot([000 000],[mn-(df*.2) mx+(df*.2)],'k');
% set(h,'linewidth',2)
xo  = (max(t) - min(t)) * 0.7 + min(t);
xd  = (max(t) - min(t)) * 0.1;
h1  = plot([xo xo+xd],[mn mn],'k');
h2  = plot([xo+xd xo+xd],[mn mn+10],'k');
text(xo+2, mn - 10, sprintf('%3.0f ms',xd));
text(xo+xd+10, mn + 5, '10 pA');
set([h1 h2],'linewidth',2)
axis tight
set(gca,'YLim',[mn-(df*.2) mx+(df*.2)]);
xlim    = get(gca,'XLim');

return

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

