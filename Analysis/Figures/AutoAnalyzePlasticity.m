function [results] = AutoAnalyzePlasticity(fid)
% Part of the AutoAnalyze suite.  Analyzes an experiment in the framework
% of an attempt to induce plasticity, either on electrical or visual
% responses.  Called from a rat/cell directory.
%
% This function attempts to figure out some things about the experiment.  
% First, whether the experiment completed (need at least three subfolders).
% Second, if there are more than three folders, which ones should be used.
% Third, if DAQ2MAT has been run in those directories.  Once these have
% been determined, the script will run a subscript to measure the amplitude
% of the responses pre and post, and to determine the spike timing.
%
% Returns, if asked for, a structure containing the pre and post data, as
% well as the spike timing data.
%
% This mfile will attempt to load a local control file (auto.mat) for help
% in determining what to do with difficult directories.  This matfile
% should contain the following structure:
%   .ignore     - if 1, the whole directory is skipped
%   .dirs       - 3x1 array with the INDICES of the dirs to use
%   .t_pre      - Nx2 array of times specifying the onset and peak latency
%   .t_post     - as with t_pre, but for post-induction
%   .t_spike    - manually set the time of the spike
%   .induced    - the index of the bar used for spatial induction
%
% $Id$

% global parameters; empty if uninitialized
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS

% determine where to write output
if nargin == 0
    fid = 1;        % write to standard out
end

% local parameters
FOLDER_SELECT   = '*';
R0_SELECT       = '*.r0';
ANALYSIS_FN_RESP    = 'AutoAnalyzeResponse';
ANALYSIS_FN_SPIKE   = 'AutoAnalyzeSpikeTiming';
ANALYSIS_FN_RF      = 'AutoAnalyzeRF';
DAQ2MAT_MODE    = 'stack';
DAQ2MAT_CHAN    = 1;
LOCAL_CONTROL   = 'auto.mat';
MIN_TRIALS      = 70;       % minimum number of trials for pre/post dirs
MIN_INDUCE      = 10;       % minimum nu8mber of trials for induction
PLOT_FIELD      = 'ampl';   %  which field to plot (ampl or slope)
DEBUG           = 0;

results         = [];

% load the control file, if there is one
if exist(LOCAL_CONTROL) ~= 0
    control     = load(LOCAL_CONTROL);
    fprintf(fid, '[%s] - loaded control file\n', LOCAL_CONTROL);
    if isfield(control,'comment')
        fprintf(fid,'[%s] - %s\n', LOCAL_CONTROL, control.comment);
    end
else
    control     = struct([]);
end

% check for ignore flag
if isfield(control,'ignore')
    if getfield(control,'ignore')
        fprintf(fid,'[%s] - Experiment ignored.\n', LOCAL_CONTROL);
        return
    end
end

% load subdirectories
start_dir   = pwd;
dd  = GetSubdirectories(FOLDER_SELECT);

len = length(dd);
fprintf(fid,'Subdirectories: %d ', len);
% check the number of daq files in each dir
for i = 1:len
    n(i)    = length(dir(fullfile(dd{i},'*.daq')));
end
if len < 3
    fprintf(fid,'\n(experiment ignored)\n');
    return
else
    if len > 3
        if isfield(control,'dirs')
            % use auto.mat if there is one
            sel     = control.dirs;
            if ~any(sel > len | sel < 0)
                fprintf(fid, '[%s] - using [%s]', LOCAL_CONTROL, num2str(control.dirs));
            else
                fprintf(fid,'\n[%s] - directory spec error\n', LOCAL_CONTROL);
                return
            end      
        else
            % try to guess on the # of trials. not super-robust
            % what we want to see is a pair of > MIN_TRIALS that are
            % separated by one or more other episodes
            sel     = [];
            above   = find(n > MIN_TRIALS);
            diffabv = diff(above);
            for i = 1:length(diffabv)
                if diffabv(i) == 2
                    sel = above(i) + [0 1 2];
                    break
                elseif diffabv(i) > 2
                    % try to guess the right induction episode
                    guess       = (above(i)+1):(above(i+1)-1);
                    aboveind    = guess(n(guess) > MIN_INDUCE);
                    if length(aboveind) > 0
                        sel = [above(i), aboveind(1), above(i+1)];
                        break
                    end
                end
            end
            if isempty(sel)
                fprintf(fid,'\n(unable to guess directories - experiment ignored)\n');
                return
            end
        end
        dd  = dd(sel);
        len = length(dd);
        n   = n(sel);
    end
    fprintf(fid,'\n');    

end

% for visual data we need to figure out which bar is induced
seq_fn  = fullfile(dd{2}, 'sequence.txt');
d       = dir(seq_fn);
if length(d) == 1
    induction_sequence = load(seq_fn);
    induced = induction_sequence(1);
    if ~all(induction_sequence==induced)
        induced = -1;           % unknown
    end
else
    induced = 0;                % electrical
end

fprintf(fid, 'Pre: %s (%d files)\n', dd{1}, n(1));
fprintf(fid, 'Induced: %s (%d files)', dd{2}, n(2));
switch induced
    case -1
        fprintf(fid,' (unknown induction bar)\n');
    case 0
        fprintf(fid,' (electrical stimulus)\n');
    otherwise
        fprintf(fid,' (%d)\n', induced);
end
fprintf(fid, 'Post: %s (%d files)\n', dd{3}, n(3));

% check that the n's are at least reasonable:
if (n(1) < MIN_TRIALS | n(3) < MIN_TRIALS) %& ~isfield(control,'dirs')
    fprintf(fid,'(too few trials - experiment ignored)\n');
    return
end
fprintf(fid, '----\n');

% check each directory for .r0 files
for i = 1:len
    d   = dir(fullfile(dd{i}, R0_SELECT));
    if isempty(d)
        cd(dd{i});
        daq2mat(DAQ2MAT_MODE, DAQ2MAT_CHAN);
        cd(start_dir);
    end
end
% run the analysis script, first in the pre/post directories, then in the
% induction directory
if isfield(control,'t_pre') & isfield(control,'t_post')
    fprintf(fid, '[%s] - using preset timing data\n', LOCAL_CONTROL);
else
    control(1).t_pre   = [];
    control(1).t_post  = [];
end
[pre,pst]   = feval(ANALYSIS_FN_RESP,dd{1},dd{3}, fid, control.t_pre, control.t_post);

fprintf(fid, '----\n');
if isfield(control,'t_spike')
    t_spike                         = control.t_spike;
    fprintf(fid,'[%s] - spike timing %3.1f\n', LOCAL_CONTROL, t_spike * 1000);
    [var, n, spikes]               = deal([]);
elseif induced ~= -1
    [t_spike, var, n, spikes]       = feval(ANALYSIS_FN_SPIKE,dd{2}, fid);
else
    [t_spike, var, n, spikes]       = deal([]);
end

% now we plot and write data to disk, if the correct global variables are
% set, and if nothing broke during the analysis
if isempty(pst) | isempty(pre)
    return
end
% generate the figures for each stimulus
for i = 1:length(pre)
    fig     = plotdata(pre(i),pst(i),t_spike,PLOT_FIELD);
    set(fig,'Name',sprintf('%s: Stimulus %d',pwd,i));
    if WRITE_FIGURES
        set(fig,'visible','on');
        fn  = sprintf('resp-%1.0f',i);
        fn  = fullfile(pwd,[fn '.fig']);
        saveas(fig,fn,'fig')
        set(fig,'visible','off')
    end
    if ~DEBUG
        delete(fig)
    else
        set(fig,'visible','on')
    end
end
% and if there are more than one, call the 
%if length(pre) > 1
%    [rf_t, rf_pre, rf_pst] = feval(ANALYSIS_FN_RF, dd{1}, dd{3}, t_spike)
%end

% package up the data for return
if nargout > 0
    % extract some parameters
    % cat will kill the empties, and the rest SHOULD be the same
    stim_electrical = cat(1,pre.stim_electrical,pst.stim_electrical);
    mode_currentclamp = cat(1,pre.mode_currentclamp,pst.mode_currentclamp);
    if ~isfield(control,'skip_ir')
        control.skip_ir = 0;
    end
    if ~isfield(control,'skip_sr')
        control.skip_sr = 0;
    end
    if ~isfield(control,'skip_slope')
        control.skip_slope = 0;
    end
    if ~isfield(control,'skip_time')
        control.skip_time = 0;
    end    
    if ~isfield(control,'comment')
        control.comment = '';
    end
    results = struct('pre',rmfield(pre,{'stim_electrical','mode_currentclamp'}),...
                     'pst',rmfield(pst,{'stim_electrical','mode_currentclamp'}),...
                     't_spike',t_spike,...
                     'spikes',spikes,...
                     'pre_dir',dd{1},...
                     'pst_dir',dd{3},...
                     'spikes_dir',dd{2},...
                     'induced',induced,...
                     'mode_currentclamp',mode_currentclamp(1),...
                     'stim_electrical',stim_electrical(1),...
                     'skip_ir',control.skip_ir,...
                     'skip_sr',control.skip_sr,...
                     'skip_slope',control.skip_slope,...,
                     'skip_time',control.skip_time,...
                     'comment',control.comment);
end

function figh   = plotdata(pre, pst, t_spike, PLOT_FIELD)
% the summary figure for this plot is going to depend on whether the
% stimulus was electrical or visual. For electrical stimulation, we'll
% plot the response, sr, and ir as a function of trace start time.
BINSIZE = 1;        % bin the IR and SR data to 1 minutes
units   = pre.([PLOT_FIELD '_units']);  %  this will be empty if pre is empty, oh well
figh    = figure;
set(figh,'visible','off')
% adjust times (if both episodes are available)
if ~isempty(pst.start) & ~isempty(pre.start)
    offset  = etime(pst.start, pre.start)/60;   % time in min between starts
    pst.time= pst.time + offset;
end
% some serious subplot-fu here
ax      = subplot(4,3,[1 2 4 5]);
plotTimeCourse(ax,pre.time,pre.(PLOT_FIELD),pst.time,pst.(PLOT_FIELD));
xlim    = get(ax,'Xlim');
ylabel(sprintf('Response (%s)',units));
title('Time Course');

if ~(isempty(pre.ir) & isempty(pst.sr))
    set(ax,'XTickLabel',[])
    ax      = subplot(4,3,[7 8]);
    plotTimeCourse(ax,pre.time,pre.ir,pst.time,pst.ir,BINSIZE);
    set(ax,'Xlim',xlim)
    ylabel('IR')
end
if ~(isempty(pre.sr) & isempty(pst.sr))
    set(ax,'XTickLabel',[])
    ax      = subplot(4,3,[10 11]);
    plotTimeCourse(ax,pre.time,pre.sr,pst.time,pst.sr,BINSIZE);
    set(ax,'Xlim',xlim)
    ylabel('SR')
end
xlabel('Time (min)')

% plot the two average responses and their difference
ax      = subplot(4,3,3);hold on
tr1     = pre.trace;
tr2     = pst.trace;
if ~isempty(tr1)
   h    = plot(pre.time_trace,tr1,'k');
   vline(pre.t_peak,'k:')
end
if ~isempty(tr2)
   h    = plot(pst.time_trace,tr2,'r');
   vline(pst.t_peak,'r:')
end
axis tight
xlim    = get(gca,'XLim');
title('Temporal RF')

if ~isempty(tr1) & ~isempty(tr2)
    set(gca,'XTickLabel',[])
    ax      = subplot(4,3,6);
    [tr_t, tr1, tr2]   = align(pre.time_trace, tr1, pst.time_trace, tr2);
    h            = plot(tr_t, tr1 - tr2, 'k');
    
    set(ax,'Xlim',xlim)
    if ~isempty(t_spike)
        vline(t_spike,'k:'),hline(0)
    end
end
xlabel('Time (s)')

function [time, a, b] = align(time1, data1, time2, data2)
start   = max([time1(1), time2(1)]);
finish  = min([time1(end), time2(end)]);
sel_1   = find(time1 >= start & time1 <= finish);
sel_2   = find(time2 >= start & time2 <= finish);
time    = time1(sel_1);
a       = data1(sel_1);
b       = data2(sel_2);
% clip vector that's too long
if length(a) > length(b)
    a       = a(1:length(b));
    time    = time2(sel_2);
elseif length(b) > length(a)
    b   = b(1:length(a));
end


function [] = plotTimeCourse(ax, pre_time, pre_data, pst_time, pst_data, binsize)
axes(ax),cla,hold on
if nargin > 5
    if ~isempty(pst_time)
        [t,d,n,st]  = TimeBin(pst_time,pst_data,binsize);
        h           = errorbar(t,d,st./sqrt(n),'k.');
    end
    if ~isempty(pre_time)
        [t,d,n,st]  = TimeBin(pre_time,pre_data,binsize);
        mn          = nanmean(d);
        h           = errorbar(t,d,st./sqrt(n),'k.');
        %h           = hline([mn * 1.3, mn * .7]);
        h           = hline([mn / 0.7, mn / 1.3]);
    end
else
    if ~isempty(pst_time)
        h       = plot(pst_time,pst_data,'k.');
        set(h,'markersize',6)
    end
    if ~isempty(pre_time)
        h       = plot(pre_time,pre_data,'k.');
        set(h,'markersize',6)
        mn      = nanmean(pre_data);
        h       = hline(mn);
    end
end

