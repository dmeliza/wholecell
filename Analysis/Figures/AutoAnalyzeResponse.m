function [pre, pst] = AutoAnalyzeResponse(pre_dir, post_dir, fid, t_pre, t_post)
% Part of the AutoAnalyze suite.  Analyzes one or two directories for the
% amplitude of the response (and the IR and SR if those can be measured)
%
% The reason this function also takes two directories is that when
% comparing pre and post we may need to keep certain analysis parameters
% constant between the two regimes.
%
% the calling function can provide times, in which case all of the magic
% event detection algorhythms are ignored

% Now, there are about 50000 ways to measure the response.  We'll start by
% doing something that doesn't duplicate what I've done by hand; that is,
% find the peak of the average response for each directory, measured
% against the baseline, which...  This is done for each r0 file in the pre
% and post directories.
%
% $Id$
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS

% check arguments and set default values
error(nargchk(1,5,nargin));
if nargin < 3
    fid = 1;
end
pre = [];
pst = [];

% analyze first directory
curdir  = pwd;
cd(pre_dir);
if nargin > 3
    pre     = analyzedirectory(fid, t_pre);
else
    pre     = analyzedirectory(fid, []);
end
cd(curdir)

% analyze second directory
if nargin > 1
    cd(post_dir)
    if nargin > 4
        pst   = analyzedirectory(fid, t_post);
    else
        pst   = analyzedirectory(fid, []); 
    end
    cd(curdir)    
end

% print results
printresults(fid, pre, pst)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = printresults(fid, pre, pst)
% print results.  Needs to be robust enough to handle empty structures,
% structures with empty fields, and God knows what else.

nconditions = max([length(pre) length(pst)]);

% if both pre and post give empty results
if nconditions == 0
    fprintf(fid,'(automatic analysis failed)\n');
else
    % if at least one side succeeded:
    for i = 1:nconditions
        % this block is necessary to avoid indexing an empty variable
        if isempty(pre)
            printcomparison(fid,[],pst(i),i);
        elseif isempty(pst)
            printcomparison(fid,pre(i),[],i);
        else
            printcomparison(fid,pre(i),pst(i),i);
        end
    end
    fprintf(fid,'----\n');
    % extract ir and sr data from all trials
    if isempty(pre)
        printresult(fid,'IR:',cat(1,pst.ir));
        fprintf(fid,'\n');
        printresult(fid,'SR:',cat(1,pst.ir));
    elseif isempty(pst)
        printresult(fid,'IR:',cat(1,pre.ir));
        fprintf(fid,'\n');
        printresult(fid,'SR:',cat(1,pre.ir));
    else
        printdifference(fid,'IR:',cat(1,pre.ir),cat(1,pst.ir),'');
        fprintf(fid,'\n');
        printdifference(fid,'SR:',cat(1,pre.sr),cat(1,pst.sr),'');
    end
    fprintf(fid,'\n');
end

function [] = printcomparison(fid,pre,pst,i)
% prints a comparison between two episodes of the same parameter
% first we have to de-struct any totally empty structures
pre         = destruct(pre);
pst         = destruct(pst);
prefix      = sprintf('R%d:',i);
if isempty(pre)
    prefix  = sprintf('%s (post; %3.0f ms)', prefix, pst.t_peak*1000);
    printresult(fid, prefix, pst.resp, pst.units);
    fprintf(' (%3.1f %s)\n', pst.time(end) - pst.time(1), 'min');
elseif isempty(pst)
    prefix  = sprintf('%s (pre; %3.0f ms)', prefix, pre.t_peak*1000);
    printresult(fid, prefix, pre.resp, pre.units);
    fprintf(' (%3.1f %s)\n', pre.time(end) - pre.time(1), 'min');    
else
    prefix  = sprintf('%s (%3.0f -> %3.0f ms)', prefix,...
        pre.t_peak*1000, pst.t_peak*1000);
    printdifference(fid, prefix, pre.resp, pst.resp, pre.units);
    fprintf(fid,' (%3.1f ; %3.1f %s)\n',...
        pre.time(end) - pre.time(1),...
        pst.time(end) - pst.time(1), 'min');    
end

function [] = printdifference(fid, prefix, pre, pst, units)
% prints the difference between two sets of data
[h,P]       = ttest2(pre,pst);
pre_m       = nanmean(pre);
pre_e       = nanstd(pre)/sqrt(length(pre));
pst_m       = nanmean(pst);
pst_e       = nanstd(pst)/sqrt(length(pst));
fprintf(fid, '%s %3.2f +/- %3.2f -> %3.2f +/- %3.2f %s (%3.1f%%; P = %3.4f)',...
    prefix, pre_m, pre_e, pst_m, pst_e, units,...
    pst_m/pre_m * 100 - 100, P);

function [] = printresult(fid, prefix, value, units)
% prints out the statistics of a single set of data
val_m   = nanmean(value);
val_e   = nanstd(value)/sqrt(length(value));
fprintf(fid, '%s %3.2f +/- %3.2f %s',...
    prefix, val_m, val_e, units);

function str = destruct(str)
% turns an empty struct into an empty variable
if isstruct(str)
    if isfield(str,'resp')
        if isempty(str.resp)
            str = [];
        end
    end
end

function [results] = analyzedirectory(fid, times);
% wrapper function loops through all r0 files in the directory
empty = struct('resp',[],'ir',[],'sr',[],'time',[],'units',[],...
    'start',[],'trace',[],'time_trace',[],'t_peak',[],'t_onset',[],'t_sr',[],...
    't_ir',[]);
d   = dir('*.r0');
dd  = {d.name};
for ifile = 1:length(dd)
    if ~isempty(times)
        Z   = analyzer0(fid, dd{ifile}, times(ifile,:));
    else
        Z   = analyzer0(fid, dd{ifile}, []);
    end
    if ~isempty(Z)
        results(ifile)  = Z;
    else
        results(ifile)  = empty;
    end
end

function [results]  = analyzer0(fid, dd, times)
% this function does all the work of analyzing each r0 file
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS

results         = [];
THRESH_ELEC     = 20;
WINDOW_RESP     = 0.5;      % no data past this is analyzed for the response
STIM_VISUAL     = 0.2;      % start time for visual stimulation
DO_FILTER       = 1;
FILTER_LP       = 1000;     % lowpass filter cutoff (Hz)
FILTER_ELEC     = 200;      % lowpass cutoff for electrical
FILTER_VIS      = 100;      % lowpass cutoff for finding peak of response
FILTER_ORDER    = 3;
THRESH_ONSET    = 3;        % X standard deviations away from mean defines onset
LENGTH_VIS      = 0.040;    % events must be at least 20 ms long
LENGTH_ELEC     = 0.010;    % electrical thresh can be lower
WINDOW_BASELN   = 0.05;     % length of the baseline to use in computing the response
WINDOW_PEAK     = 0.001;    % amount of time on either side of the peak to use
ARTIFACT_WIDTH  = 0.0015;   % width of the artifact to cut out for certain analyses
DEBUG_LOC       = 0;    

% load the r0 file, using the accompanying selector file if needed
[R, str]    = LoadResponseFile(dd);
if isempty(R)
    error(str)
end
ind_resp    = find(R.time <= WINDOW_RESP);
ind_resist  = find(R.time > WINDOW_RESP);
avg         = mean(R.data,2);
%% pre-process the file:
% determine which direction we expect the response to go
switch lower(R.y_unit{1})
    case {'v','mv'}
        iscurrentclamp = 1;
    otherwise
        iscurrentclamp = 0;
end

% if there is electrical stimulation we want to align all the
% episodes based on the artifact.  Electrical artifacts are absurdly
% fast, so the max z-score of the d/dt should exceed anything in a
% visual episode (with the exception of the transients for the voltage
% step for input resistance, but we can ignore the latter half of the
% episode
z           = zscore(diff(avg(ind_resp)));
if max(z) >= THRESH_ELEC
    iselectrical = 1;
else
    iselectrical = 0;
end
% now attempt to align the episodes if the episode is electrical
% for visual episodes we're going to assume they're aligned with a
% fixed stimulus onset time.
if iselectrical
    fprintf('Aligning traces...\n');
    [resp,time]    = AlignEpisodes(double(R.data),double(R.time),ind_resp);
    avg            = mean(resp,2);
else
    resp           = double(R.data);
    time           = double(R.time) - STIM_VISUAL;
end
% filter the data
if DO_FILTER
    resp    = filterresponse(resp,FILTER_LP,FILTER_ORDER,R.t_rate);
end
% start the plot
fig     = figure;
set(fig,'name',pwd,'visible','off'),hold on
h       = plot(time,avg,'b');

% first we try to locate the event using the statistics of the average
% response.
ind_baseline        = find(time<-0.005 & time>-0.08);
mu    = mean(avg(ind_baseline));
sigma = std(avg(ind_baseline));
% window over which to search for onset
t_sel = time>0.002 & time < WINDOW_RESP;
% search for crossing the threshold in the filtered data. filtering
% is a pain, because in electrical cases, the artifact fucks shit
% up, and we need a reasonably high cutoff to keep temporal
% resolution; in visual response we need a lowish cutoff (lower
% than 60 Hz anyway) to get around the noise problem.  So for
% electrical stimuli we cut out the artifact and filter at ~500 Hz,
% and for visual stimuli filter at around 50
if ~iselectrical
    fp              = FILTER_VIS;
    LENGTH_EVENT    = LENGTH_VIS;
    filtavg     = filterresponse(avg,fp,FILTER_ORDER,R.t_rate);
else
    fp              = FILTER_ELEC;
    THRESH_ONSET    = THRESH_ONSET * 0.66; % this may be a bad idea
    LENGTH_EVENT    = LENGTH_ELEC;
    sel_artifact= time>-ARTIFACT_WIDTH & time < ARTIFACT_WIDTH;
    in          = avg;
    in(sel_artifact)    = deal(mu);  % this isn't perfect but it's easy
    filtavg     = filterresponse(in,fp,FILTER_ORDER,R.t_rate);
end
h               = plot(time,filtavg,'k:');
legend('Response',sprintf('Filtered (%4.0f Hz)',fp));

% this stuff gets skipped if the user specified times
if isempty(times)
    if iscurrentclamp
        threshed        = filtavg > (mu + sigma * THRESH_ONSET) & t_sel;
        hline(mu + sigma * THRESH_ONSET,'r:');
    else
        threshed        = filtavg < (mu - sigma * THRESH_ONSET) & t_sel;
        hline(mu - sigma * THRESH_ONSET,'r:');
    end
    above       = find(threshed);
    % see if we can find an event onset - this usually fails when there are
    % too few traces, so we return an empty results structure.  We also
    % need to eliminate spurious crossings of the threshhold, which
    % tend to occur in the noisier traces from visual data.  In
    % particular the 60 Hz can be a real bitch.  Rather than try to
    % filter this out, we'll set a minimum crossing time for the onset
    % to count.  If this fails the user needs to set event times manually
    if ~isempty(above)
        diffabove       = diff(above);
        evbegs          = above([ 1; find(diffabove>1)+1 ]);
        evends          = above([ find(diffabove>1); length(above) ])+1;
        % eliminate events that are too long or short
        select          = (evends-evbegs)>=(LENGTH_EVENT*R.t_rate);
        evtimes         = evbegs(select);
        if ~isempty(evtimes)
            t_onset     = time(evtimes(1));
        else
            fprintf(fid, 'Err: Unable to detect event onset\n');
            writefigure(fig, dd, WRITE_FIGURES, DEBUG_LOC);
            return
        end
    else
        fprintf(fid, 'Err: Unable to detect event onset\n');
        writefigure(fig, dd, WRITE_FIGURES, DEBUG_LOC);
        return
    end            
    % now we try to locate the peak of the event. This is *tough* to do,
    % especially with visually evoked responses, since what we really want
    % is the *first* peak, not the maximum value. Finding the peak with
    % d/dt is also tricky because the value is never exactly 0; however, if
    % we only look at times after the onset, the peak should be the first
    % point at which d/dt crosses zero.  This may break if there is a
    % "hump" in the response, in which case we have to decrease the cutoff
    % for the filter to pick out the "significant" peak.  Of course, this
    % gets more difficult the lower our signal to noise ratio is.  It's
    % especially bad for visual episodes, where the 60Hz component never
    % gets averaged out.  It would be nice to be able to do this adaptively
    % - filter at a bunch of different frequencies and look for the most
    % stable t_peak....
    % filtavg         = filterresponse(avg,FILTER_PEAK,FILTER_ORDER,R.t_rate);
    t_sel           = time>=t_onset & time<=WINDOW_RESP;
    ind             = find(diff(filtavg) >= 0 & t_sel(2:end));
    t_peak          = time(ind(1));
else
    t_onset         = times(1);
    t_peak          = times(2);
end
% draw the onset and peak times
vline(t_onset,'k:')
vline(t_peak,'k')
% and now we can actually compute the response
sel_baseline    = time<t_onset & time>(t_onset-WINDOW_BASELN);
if iselectrical
    sel_artifact= time>-ARTIFACT_WIDTH & time < ARTIFACT_WIDTH;
    sel_baseline= sel_baseline & ~sel_artifact;
end
sel_response    = time>=(t_peak-WINDOW_PEAK) & time<=(t_peak+WINDOW_PEAK);
baseline        = mean(resp(sel_baseline,:),1);
response        = (mean(resp(sel_response,:),1) - baseline)';
if ~iscurrentclamp
    response    = -response;
end
at              = R.abstime(:);
% the mean event is packaged up for later fun, though setting the
% number of points to extract is tricksy...
%sel_trace       = time>(t_onset(ifile)-WINDOW_BASELN) & time < STIM_VISUAL;
sel_trace       = time >= -0.1 & time <= 0.5;
sel_trace_bl    = time>(t_onset-WINDOW_BASELN) & time < t_onset;
trace           = filtavg(sel_trace) - mean(filtavg(sel_trace_bl));
time_trace      = time(sel_trace);

%%% now calculate IR and SR
% we need to use unfiltered, unaligned data to ensure the transients
% line up
resp            = double(R.data(ind_resist,:));
r_time          = double(R.time(ind_resist));
avg             = mean(resp,2);
% with a relatively low cutoff the amplitude of the transient should be
% preserved, this gives the peak deflection (and thus roughly the
% series resistance).  This tends to break if the whole sweep clipped,
% leading to wild outliers for SR and dividing by zero for IR (because
% the transients can't be found)
warning off MATLAB:divideByZero
if ~iscurrentclamp
    offset          = 100;
    filtresp        = hpfilterresponse(resp, 1000, 3, R.t_rate);
    [m,i]           = min(filtresp(offset:end,:),[],1);
    sr              = -m(:);
    ind_trans       = i + offset;
    [m,i]           = max(filtresp,[],1);
    ind_trans2      = i;
    % calculate the IR for each trace, since the transients can tend
    % to jitter around.
    for i = 1:size(resp,2)
        % this breaks horribly if the trace clips, so we try to skip
        % the trace before that happens and record a NaN
        IND_B              = [1:300] - 400 + ind_trans(i);
        IND_R              = fix((ind_trans2(i) + ind_trans(i))/2);
        IND_R              = [IND_R:ind_trans2(i)-100];
        if any(IND_B < 0) | isempty(IND_R)
            IR(i)       = NaN;
            continue
        end
        ind_baseline    = IND_B;
        ind_ir          = IND_R;
        IR(i)           = mean(resp(ind_baseline,i),1) - mean(resp(ind_ir,i),1);
    end
    
    t_sr         = r_time(median(ind_trans)) + time(1);
    if ~isempty(IR) & ~all(isnan(IR))
        ir           = IR(:);
        t_ir         = r_time([ind_baseline(1) ind_baseline(end) ind_ir(1) ind_ir(end)]) + time(1);
        vline(t_ir);
    else
        ir       = [];
        t_ir     = [];
    end
else
    % to do: write analysis for current clamp
    ir  = [];
    sr  = [];
    t_sr       = [];
    t_ir       = [];
end
writefigure(fig, dd, WRITE_FIGURES, DEBUG_LOC);
warning on MATLAB:divideByZero
units   = R.y_unit{1};
% package in a structure (which turns the cell arrays into elements of
% a structure array)
results = struct('resp',response,'ir',ir,'sr',sr,'time',at,'units',units,...
    'start',R.start_time,'trace',trace,'time_trace',time_trace,...
    't_peak',num2cell(t_peak),'t_onset',num2cell(t_onset),'t_sr',t_sr,...
    't_ir',t_ir);
end

function [] = writefigure(fig, dd, WRITE_FIGURES, DEBUG_LOC)
% call this function to make sure the figure gets written to disk even if
% the analysis fails.
if WRITE_FIGURES
    [pn,fn,ext]     = fileparts(dd);
    fn              = fullfile(pwd,[fn '.fig']);
    set(fig,'visible','on')
    saveas(fig,fn,'fig')
    set(fig,'visible','off')
end
if ~DEBUG_LOC
    delete(fig)
else
    set(fig,'visible','on')
end

function out = filterresponse(data, cutoff, order, Fs)
% lowpass filter
Wn      = cutoff/(Fs/2);
if Wn >= 1
    Wn = 0.999;
end
[b,a]   = butter(order,Wn);
out     = filtfilt(b,a,data);

function out = hpfilterresponse(data, cutoff, order, Fs)
% from Matteo Carandini's findspikes.m
deltat = 1/Fs;
tau = 1/cutoff;
b   = [ 1-(deltat/tau)^2 2*(deltat-tau)/tau ((deltat-tau)/tau)^2];
a   = [ 1 2*(deltat-tau)/tau ((deltat-tau)/tau)^2];
out = filter(b,a,data);     % the causal filter works okay here