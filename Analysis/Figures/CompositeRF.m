function [rf, t] = CompositeRF(control, mode)
%
% RF = COMPOSITERF(CONTROL)
%
% produces a composite temporal/spatial RF from multiple data sets.
% CONTROL is the name of an xls file with the following fields:
% pre file, post file, induction bar, spike time, RF center

% $Id$

WINDOW = 150;       % ms
Fs     = 10;
SZ      = [3.5 2.9];
BINSIZE = 2.3;
MODE    = 'induced';
if nargin > 1
    MODE    = mode;
end

[data, files]   = xlsread(control);

trials  = length(files);
for i = 1:trials
    dd(:,:,i)   = CompareRF(files{i,1}, files{i,2}, data(i,2), WINDOW, data(i,1));
end

dd      = bindata(dd,BINSIZE*Fs,1);
t       = linspace(-WINDOW,WINDOW,size(dd,1));

f   = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)

switch MODE
    case 'single'
        for i = 1:trials
            induced(:,i) = dd(:,data(i,1),i);
        end
        rf      = mean(induced,2);
        h       = plot(t,rf,'k');
        axis tight
        mx      = max(abs(rf));
        set(gca,'Box','On','YLim',[-mx mx]);
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        ylabel('Change in EPSC (Normalized)');
        text(t(size(rf,1))*.4,mx*.6,sprintf('(n = %d)',trials));
    case 'induced'
        % RFs are all spatially synchronized to the induced bar (using
        % absolute distance)
        for i = 1:trials
            center  = data(i,1);
            for j = 1:size(dd,2)
                offset  = abs(center - j) + 1;      % relative distance to center
                D(:,offset,i,j) = dd(:,j,i);        % high dimensional sparse array
            end
        end
        D       = mean(D,4);                        % combine offsets
        rf      = squeeze(mean(D,3));               % combine trials
        n       = 1:size(rf,2);
        mx      = max(max(abs(rf)));
        h       = imagesc(t,n-1,rf',[-mx mx]);
        set(gca,'Box','On','YTick',n-1)
        vline(0,'k');
        xlabel('Time from Spike (ms)');
        ylabel('Distance from Induced Bar');
        colormap(redblue(0.4,200))
    case 'induced-asym'
        % RFs are spatially synchronized to the induced bar, but with
        % negative numbers signifying bars farther away from the peak and
        % positive numbers signifying bars toward the peak
        offset_offset = 4;  % have to add this to make indices work
        n             = zeros(1,7);
        for i = 1:trials
            center  = data(i,1);
            peak    = data(i,3);
            fprintf('%s (%d, %d): ', files{i,1}, center, peak);
            for j = 1:size(dd,2)
                i_off   = abs(center - j);      % relative distance to induced
                p_off   = abs(peak - j);        % relative distance to peak
                sign    = (p_off >= i_off) * -1 + (p_off < i_off);
                offset  = i_off * sign;
                fprintf('%d->%d ', j, offset);
                o       = offset + offset_offset;
                D(:,o,i,j)  = dd(:,j,i);
                n(o)        = n(o) + 1;
            end
            fprintf('\n');
        end
        D       = sum(D,4);                         % combine offsets
%         norm    = repmat(n,[size(dd,1),1,size(dd,3)]);
%         D       = D ./ norm;
        rf      = squeeze(mean(D,3));               % combine trials
        n       = (1:size(rf,2)) - offset_offset;
        mx      = max(max(abs(rf)));
        h       = imagesc(t,n,rf',[-mx mx]);
        set(gca,'Box','On','YTick',n)
        vline(0,'k');
        xlabel('Time from Spike (ms)');
        ylabel('Distance from Induced Bar');
        colormap(redblue(0.4,200))  
        
    case 'peak'
        % here we try to sort things according to both the peak of the RF
        for i = 1:trials
            peak    = data(i,3);
            for j = 1:size(dd,2)
                offset  = abs(peak - j) + 1;
                D(:,offset,i,j) = dd(:,j,i);
            end
        end
        D       = mean(D,4);
        rf      = squeeze(mean(D,3));
        n       = 1:size(rf,2);
        mx      = max(max(abs(rf)));
        h       = imagesc(t,n-1,rf',[-mx mx]);
        set(gca,'Box','On','YTick',n-1)
        vline(0,'k');
        xlabel('Time from Spike (ms)');
        ylabel('Distance from RF Center');
        colormap(redblue(0.4,200))
            
end
