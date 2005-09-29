function [d, a, b, T] = CompareRFFigure(rf1, rf2, t_spike, x_spike, window, mode)
%
% This is like CompareRF, but designed for producing example figures (no
% normalization. If run in 'single' mode it will generate the figures used
% in the top half of Figure 3 (Neuron paper), otherwise it will be the
% image in figure 4A
%
% $Id$
BINRATE = 53;
INTERP = 1;
THRESH = 1;
NORM   = [1:100];
GAMMA   = 0.6;      % this needs to be fiddled with for individual files
BAR     = [0 500];
SZ_IM   =  [3.2    2.2];
SZ_S    = [2.6 1.4];
FILTER  = 1000;
PLOT_ZM = 1;

error(nargchk(4,6,nargin))
if nargin < 6
    mode    = 'RF';
end

A = load(rf1);
B = load(rf2);
if isfield(A,'units')
    u = A.units;
else
    u = '';
end

% different windows are used by the image plot; also they are no longer
% fixed to the spike time but to the stimulus onset
switch lower(mode)
    case 'single'
        win  = [0 300];
    otherwise
        win  = [0 250];
end
        

T    = double(A.time) * 1000 - 200;
Fs   = 1/mean(diff(A.time));
Z    = find(T >= win(1));
t(1) = Z(1);
Z    = find(T <= win(2));
t(2) = Z(end);
t    = t(1):t(2);
T    = T(t);

t   = t(:);
a   = double(A.data(t,:));
b   = double(B.data(t,:));
switch lower(mode)
    case 'single'
        a   = a(:,x_spike);
        b   = b(:,x_spike);
end
if ~isempty(FILTER)
    a   = filterresponse(a,FILTER,3,Fs);
    b   = filterresponse(b,FILTER,3,Fs);
end
    
ma  = mean(a(NORM,:),1);
mb  = mean(b(NORM,:),1);
a   = a - repmat(ma,length(t),1);
b   = b - repmat(mb,length(t),1);
d   = b - a;
if strcmpi(u,'pa')
    d   = -d;
end

switch lower(mode)
    case 'single'
        % For single traces:
        f   = figure;
        set(f,'color',[1 1 1]);
        ResizeFigure(SZ_S)
        
        subplot(2,1,1)
        h = plot(T,a,'k',T,b,'r');
        set(h,'Linewidth',1)
        axis tight
        mx  = max(max([a b]));
        mn  = min(min([a b]));
        set(gca,'ylim',[mn * 1.2, mx * 1.5]);
        AddScaleBar(gca,{'',u});
        set(gca,'xcolor','white','xticklabel','');
        vline(t_spike,'k:');

        subplot(2,1,2)
        h   = plot(T,d,'k');
        axis tight
        set(h,'Linewidth',2)
        vline(t_spike,'k:');
        AddScaleBar(gca,{'ms',''},[50 0]);
        ylabel(['\DeltaResponse (pA)']);

    otherwise
        % I'd prefer to have different colormaps for the RF and difference
        % plots, but I don't think this can be done in the same figure.
        
        % Turn this on to get the old binned plot
%         [a,T] = smoothRF(a,T,BINRATE,INTERP);
%         b     = smoothRF(b,T,BINRATE,INTERP);
%         d     = smoothRF(d,T,BINRATE,INTERP);      
        if strcmpi(u,'pa')
            a   = -a;
            b   = -b;
        end
        mx  = max(max(abs([a b])));
        % The redblue colormap should be used for the difference plot; it's
        % included here for reference since the user will have to do this
        % by hand. The arguments are for 196/1, and will have to be
        % adjusted for other cells.
        figure,colormap(redblue(0.1,200,0.4))
        colormap(flipud(hot))
        ResizeFigure(SZ_IM)
        set(gcf,'Color',[1 1 1]);
        
        ax(1) = subplot(3,1,1);
        imagesc(T,1:size(a,2),a',[0 mx]);
        hold on
        cax(1) = colorbar;
        set(gca,'YTick',[],'XTickLabel',[]);
        vline(0,'k');
        ylabel('Before');

        ax(2) = subplot(3,1,2);
        imagesc(T,1:size(b,2),b',[0 mx]);
        hold on
        cax(2) = colorbar;
        vline(0,'k');
        set(gca,'YTick',[],'XTickLabel',[]);
        ylabel('After');

        ax(3) = subplot(3,1,3);
        mx1   = max(max(abs(d)));
        % should the plot have zero at the mean?
        if PLOT_ZM
            imagesc(T,1:size(d,2),d',[-mx1 mx1]);
        else
            imagesc(T,1:size(d,2),d');
        end
        set(gca,'Ytick',[]);
        hold on
        cax(3) = colorbar;
        if nargin < 5
            vline(t_spike,'w');
        else
            hold on
            x_spike     = x_spike * INTERP;
            plot(t_spike, x_spike,'k*')
        end
        vline(0,'k');
        ylabel('Delta');

        % add some extra ticks
        set(ax,'XTick',[0:50:250]);
        
        % Matlab IS INCREDIBLY INCAPABLE OF FORMATTING THIS FIGURE
        % PROPERLY, so we have to manually specify the size of the images
        sz_plot = [1.6 0.45];
        sz_clr  = [.075 0.45];
        set([ax cax],'Units','Inches');
        for i = 1:length(ax)
            p_plot  = get(ax(i),'Position');
            p_clr   = get(cax(i),'Position');
            set(ax(i),'Position',[p_plot(1:2) sz_plot]);
            set(cax(i),'Position',[p_clr(1:2) sz_clr]);
        end
end

function [d,T] = smoothRF(d,T,binrate,interp)
d   = bindata(d,binrate,1);
T   = bindata(T,binrate,1);
s   = size(d);
X   = linspace(1,s(2),s(2)*interp);  % interpolate in x dimension
t   = 1:s(1);
d   = interp2(d,X,t(:));

function [d] = thresholdRF(d,n)
% Flattens signal which does not exceed n standard deviations (from zero)
m   = mean(d(:));
%m   = 0;
s   = std(d(:)) * n;
th  = [m - s, m + s];
i   = (d > th(1)) & (d < th(2));
d(i) = m;

function out = filterresponse(data, cutoff, order, Fs)
% 60 Hz notch followed by lowpass filter
%data     = NotchFilter(data, 60, Fs, 20);

Wn      = double(cutoff/(Fs/2));
if Wn >= 1
    Wn = 0.999;
end
[b,a]   = butter(order,Wn);
out     = filtfilt(b,a,data);