function [d, a, b, T] = compareRF(rf1, rf2, t_spike, x_spike, window, mode)
%
% D = COMPARERF(rf1, rf2, bar, [pos, window, mode])
%
% stupid little figure script that loads, normalizes, and compares
% two receptive fields (or reponse fields). plots equal amounts of time
% on either side of the bar position.  BAR and WINDOW are in units
% of time. POS is the number of the position which was induced.
% ver little error checking. If MODE is set to 'single', only the induced
% bar will be shown
%
% As of 1.7, we do some threshholding and normalization that should clean
% things up a little.  As in SpatialRF, the portion of the average response
% prior to the stimulus is used to determine the baseline mean and standard
% deviation.  This is used to set the threshhold; the RF is then considered
% the portions of the EPSC that exceed that threshhold.  The entire RF is
% then normalized to the strongest peak of the pre-induction RF.
%
% $Id$
ANALYSIS_WIN      = [1 7000];      % analysis window
RF_WIN            = 150;           % size of window (ms) returned (default)
BASELINE_THRESH   = 3.5;           % # of standard deviations a response must exceeed
                                   % the mean in order to count
BINRATE = 23;                      % window is binned prior to plotting in an imagemap
INTERP  = 1;                       % amount of X interpolation to do (unused)
IMAGE   = 0;                       % display as imagesc or plots
SZ      = [3.5 3.5];               % figure size

% evaluate arguments
error(nargchk(3,6,nargin))
if nargin > 4
    RF_WIN = window;
end

% load files
A = load(rf1);
B = load(rf2);
if isfield(A,'units')
    u = A.units;
else
    u = '';
end

win  = ANALYSIS_WIN(1):ANALYSIS_WIN(2);
t    = double(A.time(win,:)) * 1000 - 200;
a    = double(A.data(win,:));
b    = double(B.data(win,:));
if nargin > 5
    a   = a(:,x_spike);
    b   = b(:,x_spike);
end

% compute threshholds and baselines
[A, a_mu, sigma]    = computeValues(a, t, BASELINE_THRESH);
[B, b_mu]           = computeValues(b, t, BASELINE_THRESH, sigma);

% cut out rf window
[a,T]               = cutRF(A, t, t_spike, RF_WIN);
b                   = cutRF(B, t, t_spike, RF_WIN);

% normalize
[m,i]               = max(abs(a));
[norm,j]           = max(abs(m));
a                   = a ./ norm;
b                   = b ./ norm;

% compute differences
d                   = b - a;

if nargout > 0
    return
end

% Plot the data
f       = figure;
set(f,'Color',[1 1 1],'Name',rf1)
ResizeFigure(f,SZ)

if size(a,2) == 1
    % for single plots
    subplot(2,1,1)
    h = plot(T,[a b]);
    set(gca,'XtickLabel',[]);
    ylabel(['Response (' u ')']);
    legend(h,{'Pre','Post'});
    vline(t_spike,'k:');
    axis tight
    
    subplot(2,1,2)
    plot(T,d);
    vline(t_spike,'k:');
    xlabel('Time (s)');
    ylabel(['Diff (rel)']);
    axis tight
    
else
    % for plots of the entire RF
    [A,T] = smoothRF(a,T,BINRATE,INTERP);
    B     = smoothRF(b,T,BINRATE,INTERP);
    D     = smoothRF(d,T,BINRATE,INTERP);
    mx    = max(max([A B]));
    mn    = min(min([B B])); 
    colormap(redblue(0.45,200))
    if IMAGE
        ax(1) = subplot(3,1,1);
        imagesc(T,1:size(A,2),A',[-mx mx]);
        axis tight
        colorbar
        
        ax(2) = subplot(3,1,2);
        imagesc(T,1:size(B,2),B',[-mx mx]);
        colorbar
        
        ax(3) = subplot(3,1,3);
        mx1   = max(max(abs(D)));
        imagesc(T,1:size(D,2),D',[-mx1 mx1]);
        colorbar

        set(ax,'YTick',1:size(D,2));
        if nargin > 3
            hold on
            p = plot(T(1)+25,x_spike,'k>');
            set(p,'MarkerFaceColor',[0 0 0])
        end
    else
        ax(1)   = subplot(3,1,1);
        p(:,1)  = plot(T,A');
        axis tight
        set(gca,'YLim',[mn mx]);
        
        ax(2)   = subplot(3,1,2);
        p(:,2)  = plot(T,B');
        set(gca,'YLim',[mn mx]);
        
        ax(3)   = subplot(3,1,3);
        p(:,3)  = plot(T,D');
        
        if nargin > 3
            set(p(x_spike,:),'LineWidth',2);
        end
    end
    % some common things happen to both image and line plots
    set(ax(1:2),'XTickLabel',[]);
    xlim    = get(ax(1),'XLim');
    set(ax, 'XLim', xlim);
    axes(ax(1));
        vline([0, t_spike], {'k','k:'});
        ylabel('Pre');
        title(rf1)
    axes(ax(2));
        vline([0, t_spike], {'k','k:'});
        ylabel('Post');
    axes(ax(3));
        vline([0, t_spike], {'k','k:'});
        ylabel('Post - Pre');
        xlabel('Time (s)');      
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [val, mu, sigma] = computeValues(data, t, BASELINE_THRESH, sigma)
% examine baseline; sigma is held constant for both RFs.
i       = find(t<=0);
mu      = mean(data(i,:,:),1);
if nargin < 4
    sigma   = std(data(i,:,:),0,1);
end
% compute values of each point relative to threshhold (zero if below)
% thresh  = repmat(mu - sigma * BASELINE_THRESH, [size(data,1), 1, 1]);
% val     = (thresh - data) .* (data < thresh);
% alternatively, compute values as a z-score
base    = repmat(mu, [size(data,1),1,1]);
thresh  = repmat(sigma, [size(data,1), 1, 1]);
% val     = (base-data) ./ thresh;
val     = (base-data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [d, T] = cutRF(d, t, t_spike, window)
% cuts out WINDOW ms on either side of T_SPIKE
Fs      = mean(diff(t));
ind     = find((t >= (t_spike - window))); % & (t <= (t_spike + window)));
ind     = ind(1):(ind(1)+ 2*window/Fs);
T       = t(ind);
d       = d(ind,:,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%555
function [d,T] = smoothRF(d,T,binrate,interp)
d   = bindata(d,binrate,1);
T   = bindata(T,binrate,1);
s   = size(d);
X   = linspace(1,s(2),s(2)*interp);  % interpolate in x dimension
t   = 1:s(1);
d   = interp2(d,X,t(:));
