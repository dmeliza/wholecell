function [] = AutoAnalyzePlasticity(fid)
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
% This mfile will attempt to load a local control file (auto.mat) for help
% in determining what to do with difficult directories.  This matfile
% should contain the following structure:
%   .ignore     - if 1, the whole directory is skipped
%   .dirs       - 3x1 array with the INDICES of the dirs to use
%   .t_pre      - Nx2 array of times specifying the onset and peak latency
%   .t_post     - as with t_pre, but for post-induction
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
DAQ2MAT_MODE    = 'stack';
DAQ2MAT_CHAN    = 1;
LOCAL_CONTROL   = 'auto.mat';
DEBUG           = 1;

% load the control file, if there is one
if exist(LOCAL_CONTROL) ~= 0
    control     = load(LOCAL_CONTROL);
    fprintf(fid, '[%s] - loaded control file\n', LOCAL_CONTROL);
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
fprintf(fid,'Subdirectories: %d ', len)

if len < 3
    fprintf(fid,'\n(experiment ignored)\n');
    return
else
    if len > 3
        if isfield(control,'dirs')
            try
                dd  = dd(control.dirs);
                len = length(dd);
                fprintf(fid, '[%s] - using [%s]', LOCAL_CONTROL, num2str(control.dirs));
            catch
                fprintf(fid,'\n[%s] - directory spec error\n', LOCAL_CONTROL);
                return
            end
        else
            fprintf(fid,'\n(experiment ignored)\n');
            return
        end
    end
    % check each directory for .r0 files
    fprintf(fid,'\n');
    for i = 1:len
        d   = dir(fullfile(dd{i}, R0_SELECT));
        if isempty(d)
            cd(dd{i});
            daq2mat(DAQ2MAT_MODE, DAQ2MAT_CHAN);
            cd(start_dir);
        end
    end
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

fprintf(fid, 'Pre: %s\n', dd{1});
fprintf(fid, 'Induced: %s', dd{2});
switch induced
    case -1
        fprintf(fid,' (unknown induction bar)\n')
    case 0
        fprintf(fid,' (electrical stimulus)\n')
    otherwise
        fprintf(fid,' (%d)\n', induced)
end
fprintf(fid, 'Post: %s\n', dd{3});
fprintf(fid, '----\n')
% run the analysis script, first in the pre/post directories, then in the
% induction directory
if isfield(control,'t_pre') & isfield(control,'t_post')
    fprintf(fid, '[%s] - using preset timing data\n', LOCAL_CONTROL);
else
    control(1).t_pre   = [];
    control(1).t_post  = [];
end
[pre,pst]   = feval(ANALYSIS_FN_RESP,dd{1},dd{3}, fid, control.t_pre, control.t_post);

fprintf(fid, '----\n')
if induced ~= -1
    t_post       = feval(ANALYSIS_FN_SPIKE,dd{2}, fid);
end

% now we plot and write data to disk, if the correct global variables are
% set, and if nothing broke during the analysis
if isempty(pst) | isempty(pre)
    return
end
% generate the figures for each stimulus
for i = 1:length(pre)
    fig     = plotdata(pre(i),pst(i),t_post);
    set(fig,'Name',sprintf('Stimulus %d',i));
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

function figh   = plotdata(pre, pst, t_post)
% the summary figure for this plot is going to depend on whether the
% stimulus was electrical or visual. For electrical stimulation, we'll
% plot the response, sr, and ir as a function of trace start time.
BINSIZE = 1;        % bin the IR and SR data to 1 minutes
figh    = figure;
set(figh,'visible','off')
% adjust times
offset  = etime(pst.start, pre.start)/60;   % time in min between starts
pst.time= pst.time + offset;
% some serious subplot-fu here
ax      = subplot(4,3,[1 2 4 5]);
plotTimeCourse(ax,pre.time,pre.resp,pst.time,pst.resp);
set(ax,'XTickLabel',[])
xlim    = get(ax,'Xlim');
ylabel(sprintf('Response (%s)',pre.units));
title('Time Course');

ax      = subplot(4,3,[7 8]);
plotTimeCourse(ax,pre.time,pre.ir,pst.time,pst.ir,BINSIZE);
set(ax,'XTickLabel',[],'Xlim',xlim)
ylabel('IR')

ax      = subplot(4,3,[10 11]);
plotTimeCourse(ax,pre.time,pre.sr,pst.time,pst.sr,BINSIZE);
set(ax,'Xlim',xlim)
ylabel('SR')
xlabel('Time (min)')

% plot the two average responses and their difference
ax      = subplot(4,3,3);
tr1     = pre.trace - mean(pre.trace(1:50));
tr2     = pst.trace - mean(pst.trace(1:50));
h       = plot(pre.time_trace,tr1,'k',pst.time_trace,tr2,'r');
axis tight, set(gca,'XTickLabel',[])
xlim    = get(gca,'XLim');
vline(t_post,'k:')
title('Temporal RF')
ax      = subplot(4,3,6);
% this may break...
h       = plot(pre.time_trace,tr1 - tr2,'k');
set(gca,'Xlim',xlim)
vline(t_post,'k:'),hline(0)
xlabel('Time (s)')


function [] = plotTimeCourse(ax, pre_time, pre_data, pst_time, pst_data, binsize)
axes(ax),cla,hold on
if nargin > 5
    [t,d,n,st]  = TimeBin(pre_time,pre_data,binsize);
    mn          = nanmean(d);
    h           = errorbar(t,d,st./sqrt(n),'k.');
    [t,d,n,st]  = TimeBin(pst_time,pst_data,binsize);
    h           = errorbar(t,d,st./sqrt(n),'k.');
    h           = hline([mn * 1.3, mn * .7]);
else
    h       = plot(pre_time,pre_data,'k.');
    set(h,'markersize',6)
    mn      = nanmean(pre_data);
    h       = plot(pst_time,pst_data,'k.');
    set(h,'markersize',6)
    h       = hline(mn);
end

