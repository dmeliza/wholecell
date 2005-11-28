function [out] = GroupModelTemporal(params)
%
% Runs ModelTemporal() on several different timings to create a composite
% timing window. Returns a structure containing the average change to EPSC,
% wPSTH, and synaptic weights
%
% $Id$

WINDOW  = 100;
dt   = [-100:2:100];

for i = 1:length(dt)
    params.t_spike  = dt(i);
    [dZ(:,i),dR(:,i),dw(:,i),tt(:,i),t(:,i)]   = ModelTemporal(params);
end

Fs     = mean(diff(tt(:,1)));
[T,R]  = TimeBin(tt(:),dR,Fs);
[T,Z,n] = TimeBin(tt(:),dZ,Fs);
[lag,W,n_W,SD_W] = TimeBin(t(:),dw(:),5);

out     = struct('T',T,'R',R,'Z',Z,...
                 'lag',lag,'W',W);

if nargout > 0
    return
end

figure
set(gcf,'Color',[1 1 1])
ResizeFigure([9.5 2.75])

subplot(1,3,1)
plot(T,R*100,'k');
set(gca,'XLim',[-WINDOW WINDOW]);
ylabel('\DeltaResponse (EPSC,%)');
xlabel('Time from Spike (ms)');
vline(0,'k:'),hline(0,'k:')

subplot(1,3,2)
plot(T,Z*100,'k');
vline(0,'k:'),hline(0,'k:')
set(gca,'XLim',[-WINDOW WINDOW]);
ylabel('\DeltaResponse (wPSTH,%)');
xlabel('Time from Spike (ms)');

subplot(1,3,3)
plot(lag,log10(W),'ko');
yt  = [0.25 0.5 1 2 4];
set(gca,'YTick',log10(yt),'YTickLabel',num2str(yt'*100),...
    'XLim',[-WINDOW WINDOW]);
ylabel('\DeltaSynaptic Weight (%)');
xlabel('Time from Spike (ms)');
vline(0,'k:'),hline(0,'k:')

