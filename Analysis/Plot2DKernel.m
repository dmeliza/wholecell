function Plot2DKernel(hl_est,resp,stim,stim_times,stim_dim,Fs)
% Plots results of 2D reverse correlation, averaging successive estimations
% and computing the correlation coefficient for each run.
% hl_est - the estimated kernel (most recent estimation)
% stim - the stimulus
% 
%
% $Id$

% Figure setup
f = findobj('tag','revcor_results');
if isempty(f)
    f = figure('tag','revcor_results');
end
figure(f);
set(f,'color',[1 1 1],'Position',[289    45   800   239]);
clf;
% Load old data
old_kernel = get(f,'UserData');
if size(old_kernel,1)==size(hl_est,1) & size(old_kernel,2)==size(hl_est,2)
    old_kernel = cat(3,old_kernel,hl_est);
    hl_est = mean(old_kernel,3);
else
    old_kernel = hl_est;
end
trials = size(old_kernel,3);
set(f,'UserData',old_kernel,'Name',['RevCor Results (' num2str(trials) ')']);

subplot(1,3,1)
    mx = max(max(abs(hl_est)));
    CLIM = [-mx mx];
    imagesc(hl_est,CLIM)
    set(gca,'XTick',[],'YTick',[])
    xlabel('Parameters')
    ylabel(['Lags (CV = 'num2str(std(diff(stim_times))/mean(diff(stim_times))) ')']);
    colormap(gray)    
subplot(1,3,2)
    k = mean(hl_est(1:3,:),1);
    k = reshape(k,stim_dim(1),stim_dim(2));
    mx = max(max(abs(k)));
    imagesc(k,[-mx mx]);
    set(gca,'XTick',[],'YTick',[])
subplot(1,3,3)
    s = size(hl_est);
    y_est = StimulusMatrix(stim,s(1)) * reshape(hl_est,s(1)*s(2),1);
    r = corrcoef(y_est,resp);
    y_est = y_est * max(resp)/max(y_est);
    t = 0:1000/Fs:1000*(length(resp)-1)/Fs;
    plot(t,resp,'-b')
    hold on
    plot(t,y_est,'-r')
    axis square
    set(gca,'YTick',[])
    xlabel('Time (ms)')
    ylabel('Response')
    title(['Corr Coef: ' num2str(r(1,2))])