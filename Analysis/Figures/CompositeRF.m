function [rf, t] = CompositeRF(control, mode)
%
% RF = COMPOSITERF(CONTROL, MODE)
%
% produces a composite temporal/spatial RF from multiple data sets.
% CONTROL is the name of an xls file with the following fields:
% pre file, post file, induction bar, spike time, RF center (x), RF center (t), onset latency (induced) 
%
% COMPOSITERF operates in several modes
% 'single' - plots the induced bar only
% 'induced' - assigns spatial values based on absolute distance to induced bar
% 'induced-asym' - like 'induced', but with positive values toward the
%                  center, and negative values toward the surround
% 'peak'    - assigns values based on distance to peak (doesn't work well)

% $Id$

DELTA   = [0 50]; % only pre-post timings in this range are used
INDUCED = 'surround'; % can be 'center', 'surround', or 'all'
MIN_EVENT   = 10;   % set a minimum event size to avoid normalization problems
WINDOW = 150;       % ms; switch to 250 for the wider window in fig 2
Fs     = 10;
SZ      = [3.4 2.9];
SE      = 0;        % if 1, plot standard error
BINSIZE = 4.3;
MODE    = 'induced';
if nargin > 1
    MODE    = mode;
end

% load control data from file
[data, files]   = xlsread(control);
t_spike         = data(:,2);
t_peak          = data(:,4);
x_induced       = data(:,1);
x_center        = data(:,3);
% do some prefiltering:
% determine which expt's have the right induction intervals
delta           = t_spike - t_peak;
ind_d           = delta >= DELTA(1) & delta <= DELTA(2);
% select center-induced or surround-induced
switch INDUCED
    case 'center'
        ind_i   = x_induced == x_center;
    case 'surround'
        ind_i   = x_induced ~= x_center;
    otherwise
        ind_i   = ones(size(x_induced));
end
ind = ind_d & ind_i;
% restrict analysis to those expts
files           = files(ind,:);
t_spike         = data(ind,2);  % time of spike
t_center        = data(ind,4);  % induced peak
x_induced       = data(ind,1);  % induced bar 
x_center        = data(ind,3);  % strongest response
t_onset         = data(ind,5);  % time of onset of induced response
delta           = delta(ind);

trials  = length(files);
for i = 1:trials
    fprintf('%s: (delta = %d)\n',files{i,1},delta(i));
    [dd(:,:,i), aa(:,:,i), bb(:,:,i), T(:,i)]   = CompareRF(files{i,1},...
        files{i,2}, t_spike(i), x_induced(i), WINDOW);
end

dd      = bindata(dd,BINSIZE*Fs,1);
t       = linspace(-WINDOW,WINDOW,size(dd,1));

f   = figure;
set(f,'Color',[1 1 1])
ResizeFigure(f,SZ)

switch MODE
    case 'single'
        hold on
        for i = 1:trials
            induced(:,i) = dd(:,x_induced(i),i);
        end
        rf      = mean(induced,2);
        h       = plot(t,rf,'k');
        mx      = max(max(abs(rf)));
%         rf_bs   = my_bootstrp(500,induced);
%         rf_ci   = prctile(rf_bs',[2.5 97.5]);
        if SE
            rf_err  = std(induced,[],2)/sqrt(size(induced,2));
            rf_ci   = rf_err * tinv(.975,size(induced,2)-1);
            rf_ci   = [rf - rf_ci, rf + rf_ci];
            h2      = plot(t,rf_ci','k:');
            mx      = max(max(abs(rf_ci)));
        end
        axis tight
        set(gca,'Box','On','YLim',[-mx mx]);
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        ylabel('Change in EPSC (Normalized)');
        text(t(size(rf,1))*.4,mx*.6,sprintf('(n = %d)',trials));
    case 'single-ci'
        % computes confidence intervals.  Note that if the population isn't
        % homogeneous, conventional statistics won't work.  So we split the
        % graph into positive and negative delays and compute the mean and
        % CI for each separately
        LTP = [];
        LTD = [];
        for i = 1:trials
            if delta(i) > 0
                LTP = cat(2,LTP,dd(:,x_induced(i),i));
            else
                LTD = cat(2,LTD,dd(:,x_induced(i),i));
            end
        end
%         LTP_bs  = my_bootstrp(500,LTP);
%         LTD_bs  = my_bootstrp(500,LTD);
%         LTP_rf  = mean(LTP_bs,2);
%         LTD_rf  = mean(LTD_bs,2);
%         LTP_ci  = (prctile(LTP_bs',[2.5 97.5]))';
%         LTD_ci  = (prctile(LTD_bs',[2.5 97.5]))';
        LTP_rf  = mean(LTP,2);
        LTD_rf  = mean(LTD,2);
        LTD_er  = std(LTP,[],2)/sqrt(size(LTD,2));% * tinv(.975,size(LTP,2)-1);
        LTP_er  = std(LTD,[],2)/sqrt(size(LTD,2));% * tinv(.975,size(LTD,2)-1);
        LTP_ci  = [LTP_rf - LTP_er, LTP_rf + LTP_er];
        LTD_ci  = [LTD_rf - LTD_er, LTD_rf + LTD_er];
        a1 = subplot(1,2,1);
            ind = find(t<0);
            hold on
            plot(t(ind),LTP_rf(ind),'k');
            plot(t(ind),LTP_ci(ind,:),'k:');
%            plot(t(ind),LTP(ind,:));
            title('LTP')
            hline(0)
        a2 = subplot(1,2,2);
            ind = find(t>0);
            hold on
            plot(t(ind),LTD_rf(ind),'k');
            plot(t(ind),LTD_ci(ind,:),'k:');
            title('LTD')
%            plot(t(ind),LTD(ind,:));
            hline(0)
        mx      = max(max(abs([LTP_ci LTD_ci])));
        set([a1 a2],'Box','On','YLim',[-mx mx]);
        set(a2,'YTickLabel','')
        
    case 'centersurround'
        % plots windows for the center and the surround
        x1       = abs(x_induced - x_center);
        centers  = (find(x1 == 0))';
        surround = (find(x1 == 1))';
        wayout   = (find(x1 > 1))';
        for i = 1:length(centers)
            c   = centers(i);
            rf_cent(:,i)    = dd(:,x_induced(c),c);
        end
        for i = 1:length(surround)
            s   = surround(i);
            rf_surr(:,i)    = dd(:,x_induced(s),s);
        end
        for i = 1:length(wayout)
            s   = wayout(i);
            rf_way(:,i)    = dd(:,x_induced(s),s);
        end
        rf      = [mean(rf_cent,2), mean(rf_surr,2), mean(rf_way,2)];
        rf      = [mean(rf_cent,2), mean([rf_surr rf_way],2)];
        h   = plot(t,[rf]);
%         x1  = abs(x_induced - x_center);        % distance from peak
%         sel = find(x1==0);
%         rf(:,1) = mean(dd(:,x_induced(sel),sel),2);
%         sel = find(x1==1);
%         rf(:,2) = mean(dd(:,x_induced(sel),sel),2);
%         sel = find(x1 > 1);
%         rf(:,3) = mean(dd(:,x_induced(sel),sel),2);
%         h   = plot(t,rf);
%        legend(h,'x1 = 0', 'x1 = 1', 'x1 > 1')
        legend(h,'Center', 'Surround')
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        ylabel('Change in EPSC (Normalized)');
    case 'latency'
        % plots windows for low latency and high latency
        t_cutoff    = 100;
        early       = (find(t_onset <= t_cutoff))';
        late        = (find(t_onset > t_cutoff))';
        for i = 1:length(early)
            c   = early(i);
            rf_early(:,i)   = dd(:,x_induced(c),c);
        end
        for i = 1:length(late)
            c   = late(i);
            rf_late(:,i)    = dd(:,x_induced(c),c);
        end
        rf  = [mean(rf_early,2), mean(rf_late,2)];
        h   = plot(t,[rf]);
        legend(h,'onset < 100','onset >= 100');
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        ylabel('Change in EPSC (Normalized)');
    case 'surround-center'
        % answers the question, what happens to the center when you induce
        % in the surround?
        hold on
        x_induced
        one_off = x_induced + sign(x_center - x_induced)
        for i = 1:length(one_off)
            induced(:,i)     = dd(:,x_induced(i),i);
            noninduced(:,i)  = dd(:,one_off(i),i);
        end
        rf      = mean(induced,2);
        rf2     = mean(noninduced,2);
        h       = plot(t,rf,'k',t,rf2,'b');
        mx      = max(max(abs([rf rf2])));
        if SE
            rf_se   = std(induced,[],2)/sqrt(size(induced,2));
            rf2_se  = std(noninduced,[],2)/sqrt(size(noninduced,2));
            h2      = plot(t,rf+rf_se,'k:',t,rf-rf_se,'k:',...
                           t,rf2+rf2_se,'b:',t,rf2-rf2_se,'b:');
        end                       
        legend(h,'surr (cond)','peak');
        legend boxoff
        axis tight
        set(gca,'Box','On','YLim',[-mx mx]);
        ylim   = get(gca,'YLim');
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        ylabel('Change in EPSC (Normalized)');
        text(t(size(rf,1))*.4,mx*.6,sprintf('(n = %d)',trials));        
        % compute significance of 50 ms bins
        for i = -150:50:100
            tt      = find(t>=i&t<(i+50));
            X       = mean(induced(tt,:),1);
            Y       = mean(noninduced(tt,:),1);
%            [h,p]   = ttest2(X,Y);
            [h,p]   = ttest(Y,0);
            if h
                plot(i+25,ylim(end) * 0.8,'k*');
                fprintf('[%d,%d): %3.3f\n',i,i+50,p);
            end
        end
    case 'center-surround'
        % answers the question, what happens to the surround when you induce
        % in the center?  The surround here is considered to be the average
        % of the two nearest bars (or should it be all other bars?)
        x_induced
        hold on
        noninduced = [];
        for i = 1:length(x_induced)
            induced(:,i)     = dd(:,x_induced(i),i);
            nind             = x_induced(i) + [-1 1];
            nind             = intersect(nind,[1 2 3 4]);
%            nind             = setdiff([1 2 3 4], x_induced(i));
            for j = nind
                noninduced   = cat(2,noninduced,dd(:,j,i));
            end
        end
        rf      = mean(induced,2);
        rf2     = mean(noninduced,2);
        h       = plot(t,rf,'k',t,rf2,'b');
        mx      = max(max(abs([rf rf2])));
        if SE
            rf_se   = std(induced,[],2)/sqrt(size(induced,2));
            rf2_se  = std(noninduced,[],2)/sqrt(size(noninduced,2));
            h2      = plot(t,rf+rf_se,'k:',t,rf-rf_se,'k:',...
                           t,rf2+rf2_se,'b:',t,rf2-rf2_se,'b:');
        end
        legend(h,'peak (cond)','surround');
        legend boxoff
        axis tight
        set(gca,'Box','On','YLim',[-mx mx]);
        vline(0),hline(0)
        xlabel('Time from Spike (ms)');
        ylabel('Change in EPSC (Normalized)');
        text(t(size(rf,1))*.4,mx*.6,sprintf('(n = %d)',trials));        
        tt      = find(t>=0&t<50);
        X       = mean(induced(tt,:),1);
        Y       = mean(noninduced(tt,:),1);
        [h,p]   = ttest(X,0)
    case 'supercube'
        % ugh. in this case we categorize each column in the dd matrix by
        % its x1 (distance between x_induced and x_center) and x2 (distance
        % between x and x_induced, x2>0 if toward center) parameters.
        x1  = x_induced - x_center;
        x   = repmat([1 2 3 4],trials,1);
        x2  = (x - repmat(x_induced,1,4));
        for i = 1:length(x1)
            if x1(i) == 0
                x2(i,:) = -abs(x2(i,:));
            elseif x1(i) > 0
                x2(i,:) = -x2(i,:);
            end
        end
        x1      = abs(x1);
        x1_vals = min(x1):max(x1);
        x2_vals = min(min(x2)):max(max(x2));
        x1      = repmat(x1,1,4);       % expand this for easier searches
        for i = 1:length(x1_vals)
            for j = 1:length(x2_vals)
                ii    = x1_vals(i);
                jj    = x2_vals(j);
                [m,n] = find(x1==ii & x2==jj);
                fprintf('X1=%d, X2=%d: ',ii,jj);
                if isempty(m) | isempty(n)
                    fprintf('(none)');
                    %SC(:,i,j)   = repmat(NaN,size(dd,1),1);
                else
                    for k = 1:length(m)
                        Z(:,k)  = dd(:,n(k),m(k));
                        fprintf('[%d,%d] ',n(k),m(k));
                    end
                    SC(:,i,j)   = mean(Z,2);
                    NC(i,j)     = k;        % number of cells in each spot
                    clear Z
                end
                fprintf('\n');
            end
        end
        mx  = max(max(max(SC)));
        mn  = min(min(min(SC)));
        mx  = max(abs([mn mx]));
        LTP_win = find(t > -50 & t < 0);
        LTD_win = find(t > 0 & t < 50);
        LTP = squeeze(mean(SC(LTP_win,:,:),1));
        LTD = squeeze(mean(SC(LTD_win,:,:),1));
        subplot(2,1,1)
        imagesc(x2_vals,x1_vals,LTP,[-mx mx]);
        ylabel('X1: Distance from Center');
        title('LTP (0 ms > t > 50 ms)')
        subplot(2,1,2)
        imagesc(x2_vals,x1_vals,LTD,[-mx mx]);
        ylabel('X1: Distance from Center');
        xlabel('X2: Distance from Induced Bar');
        title('LTD (-50 ms > t > 0 ms)')
        colormap(redblue(0.5))
        resizefigure([3.44 4.1]);
        % plot some diagnostics:
        % compress columns
        wm      = repmat(permute(NC,[3 1 2]),size(SC,1),1);
        wsc     = wm .* SC;
        wcol    = squeeze(sum(wm,2));
        wrow    = squeeze(sum(wm,3));
        col     = squeeze(sum(wsc,2)) ./ wcol;
        % compress rows
        row     = squeeze(sum(wsc,3)) ./ wrow;
        % single trace
        rowcol  = squeeze(sum(col,2)) ./ squeeze(sum(wcol,2));
        % traces for each x1,x2 pair
        figure
        n   = 1;
        for i = 1:(length(x1_vals)+1)
            for j = 1:(length(x2_vals)+1)
                subplot(length(x1_vals)+1, length(x2_vals)+1, n)
                if i > length(x1_vals)
                    if j > length(x2_vals)
                        plot(t,rowcol,'k');
                    else
                        plot(t,col(:,j),'k');
                    end
                elseif j > length(x2_vals)
                    plot(t,row(:,i),'k');
                else
                    plot(t,squeeze(SC(:,i,j)));
                end
                axis tight
                vline(0),hline(0)
                n   = n + 1;
            end
        end
%        val = col ./ repmat(w,size(col,1),1);
%        keyboard
        
        
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
        set(gca,'Box','On','YTick',n,'YLim',[-2.5 2.5])
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


function out = my_bootstrp(nboot, data)
% computes a bootstrap of the rowwise mean of a data matrix
sz  = size(data);
bootsam = unidrnd(sz(2),sz(2),nboot);
for i = 1:nboot
    out(:,i) = mean(data(:,bootsam(:,i)),2);
end
    