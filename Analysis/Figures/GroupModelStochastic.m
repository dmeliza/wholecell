function [res] = GroupModelStochastic(params, stochs)
%
% Runs GroupModelTemporal() on a variety of stoch ratios.
%
%

params.time = [-500 500];

for i = 1:length(stochs)
    params.stoch = stochs(i);
    fprintf('Stoch ratio: %3.2f\n', stochs(i));
    [res(i)]  = GroupModelTemporal(params);
end

if nargout > 0
    return
end

figure
ResizeFigure([6.7 2.9])
subplot(1,2,1)
p   = plot(res(1).T,[res.R]);
legend(num2str(stochs'))
axis tight
set(gca,'Xlim',[-250 250],'YTick',[])
vline(0),hline(0)
xlabel('Time from Spike (ms)')
ylabel('\DeltaResponse (EPSC)')
c   = get(p,'Color');

subplot(1,2,2)
hold on
for i = 1:length(res)
    p   = plot(res(i).lag, res(i).W*100);
    set(p,'Color',c{i});
end
legend(num2str(stochs'))
set(gca,'XLim',[-120 120])
hline(100),vline(0)
xlabel('Time from Spike (ms)')
ylabel('\DeltaSynaptic Weight (%)')


return

for i = 1:length(res)
    [m(i),j]    = max(res(i).W);
    pk(i)       = res(i).lag(j);
end
[ax h1 h2] = plotyy(stochs,m*100,stochs,pk);
set(ax,'nextplot','add')
set([h1 h2],'linestyle','none','marker','.','markersize',15)
[coefs, p, rsq] = LinFit(stochs,pk);
plot(ax(2),stochs,polyval(coefs,stochs),'k')
xlabel('\sigma_\epsilon/\sigma_t')
ylabel(ax(1),'Max \DeltaSynaptic Weight (%)')
ylabel(ax(2),'Peak of Effective STDP Window')
