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

% write parameters
if WRITE_PARAMETERS
    writeparameters(pre, pst)
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
    % figure out length of episodes
    pre_t   = cat(1,pre.time);
    pst_t   = cat(1,pst.time);
    pre_len = max(pre_t) - min(pre_t);
    pst_len = max(pst_t) - min(pst_t);
    if ~isempty(pre_len)
        fprintf(fid,'(pre)  - %3.1f %s\n', pre_len, 'min');
    end
    if ~isempty(pst_len)
        fprintf(fid,'(post) - %3.1f %s\n', pst_len, 'min');
    end        
    % if at least one side succeeded:
    for i = 1:nconditions
        % this block is necessary to avoid indexing an empty variable
        if isempty(pre)
            A   = [];
            B   = pst(i);
        elseif isempty(pst)
            A   = pre(i);
            B   = [];
        else
            A   = pre(i);
            B   = pst(i);
        end
        printcomparison(fid, 'RA', A, B, 'ampl', i);
        printcomparison(fid, 'RS', A, B, 'slope', i);
    end
    fprintf(fid,'----\n');
    % extract ir and sr data from all trials
    if isempty(pre)
        printresult(fid,'IR:',cat(1,pst.ir));
        fprintf(fid,'\n');
        printresult(fid,'SR:',cat(1,pst.ir));
        fprintf(fid,'\n');
        printresult(fid,'LK:',cat(1,pst.leak));        
    elseif isempty(pst)
        printresult(fid,'IR:',cat(1,pre.ir));
        fprintf(fid,'\n');
        printresult(fid,'SR:',cat(1,pre.ir));
        fprintf(fid,'\n');
        printresult(fid,'LK:',cat(1,pre.leak));        
    else
        printdifference(fid,'IR:',cat(1,pre.ir),cat(1,pst.ir),'');
        fprintf(fid,'\n');
        printdifference(fid,'SR:',cat(1,pre.sr),cat(1,pst.sr),'');
        fprintf(fid,'\n');
        printdifference(fid,'LK:',cat(1,pre.leak),cat(1,pst.leak),'');
    end
    fprintf(fid,'\n');
end

function [] = printcomparison(fid,prefix,pre,pst,field,i)
% prints a comparison between two episodes of the same parameter
% first we have to de-struct any totally empty structures
ARR         = char(187);    % an arrow character
pre         = destruct(pre,field);
pst         = destruct(pst,field);
prefix      = sprintf('%s%d:',prefix,i);
if isempty(pre) & isempty(pst)
    fprintf(fid,'%s No event detected.\n',prefix);
elseif isempty(pre)
    prefix  = sprintf('%s (post) [%3.0f/%3.0f ms]', prefix, pst.t_onset*1000,...
        pst.t_peak*1000);
    printresult(fid, prefix, pst.(field), pst.([field '_units']));
    % compute slope of response
    [z, s]  = polyfit(pst.time, pst.(field),1);
    fprintf(fid,' (%2.1f %s/%s) \n', z(1), pst.([field '_units']), 'min');
elseif isempty(pst)
    prefix  = sprintf('%s (pre) [%3.0f/%3.0f ms]', prefix, pre.t_onset*1000,...
        pre.t_peak*1000);
    printresult(fid, prefix, pre.(field), pre.([field '_units']));
    % compute slope of response
    [z, s]  = polyfit(pre.time, pre.(field),1);
    fprintf(fid,' (%2.1f %s/%s) \n', z(1), pre.([field '_units']), 'min');
else
    prefix  = sprintf('%s [%1.0f/%1.0f %s %1.0f/%1.0f ms]', prefix,...
        pre.t_onset*1000, pre.t_peak*1000, ARR, pst.t_onset*1000,pst.t_peak*1000);
    printdifference(fid, prefix, pre.(field), pst.(field), pre.([field '_units']));
    % compute slope of response
    [z1, s]  = polyfit(pre.time, pre.(field),1);
    [z2, s]  = polyfit(pst.time, pst.(field),1);
    fprintf(fid,' (%2.1f;%2.1f %s/%s) \n', z1(1), z2(1), pst.([field '_units']), 'min');
end

function [] = printdifference(fid, prefix, pre, pst, units)
% prints the difference between two sets of data
PLMN    = char(177);    % the plus-minus character
ARR     = char(187);    % an arrow character
if isempty(pre) & isempty(pst)
    return
elseif isempty(pre)
    printresult(fid,prefix,pst,units);
elseif isempty(pst)
    printresult(fid,prefix,pre,units);
else
    [h,P]       = ttest2(pre,pst);
    pre_m       = nanmean(pre);
    pre_e       = nanstd(pre)/sqrt(length(pre));
    pst_m       = nanmean(pst);
    pst_e       = nanstd(pst)/sqrt(length(pst));
    fprintf(fid, '%s %3.2f%s%3.2f %s %3.2f%s%3.2f %s (%3.1f%%; P = %3.3f)',...
        prefix, pre_m, PLMN, pre_e, ARR, pst_m, PLMN, pst_e, units,...
        pst_m/pre_m * 100 - 100, P);
end

function [] = printresult(fid, prefix, value, units)
% prints out the statistics of a single set of data
PLMN    = char(177);    % the plus-minus character
val_m   = nanmean(value);
val_e   = nanstd(value)/sqrt(length(value));
fprintf(fid, '%s %3.2f%s%3.2f %s',...
    prefix, val_m, PLMN, val_e, units);

function str = destruct(str,field)
% turns an empty struct into an empty variable
if isstruct(str)
    if isfield(str,field)
        if isempty(str.(field))
            str = [];
        end
    end
end

function [results] = analyzedirectory(fid, times);
% wrapper function loops through all r0 files in the directory
empty = struct('ampl',[],'slope',[],'ir',[],'sr',[],'leak',[],'time',[],...
    'ampl_units',[],'slope_units',[],...
    'start',[],'trace',[],'filttrace',[],'time_trace',[],...
    't_peak',[],'t_onset',[],'t_sr',[],...
    't_ir',[],'stim_electrical',[],'stim_start',[],...
    'mode_currentclamp',[]);
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
FILTER_ORDER    = 3;
WINDOW_BASELN   = 0.05;     % length of the baseline to use in computing the response
WINDOW_PEAK     = 0.001;    % amount of time on either side of the peak to use
ARTIFACT_WIDTH  = 0.0015;   % width of the artifact to cut out for certain analyses
SLOPE_PT        = 0.003;    % point at which to take the slope
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
        isCC = 1;
    otherwise
        isCC = 0;
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

[t_onset, t_peak, filtavg] = findEvents(avg, time, R.t_rate, times,...
    isCC, iselectrical, WINDOW_RESP);

if ~isempty(t_onset) & ~isempty(t_peak)
    % draw the onset and peak times
    vline(t_onset,'k:')
    vline(t_peak,'k')
    % and now we can actually compute the response, if we found an event
    sel_baseline    = time<t_onset & time>(t_onset-WINDOW_BASELN);
    if iselectrical
        sel_artifact= time>-ARTIFACT_WIDTH & time < ARTIFACT_WIDTH;
        sel_baseline= sel_baseline & ~sel_artifact;
    end
    sel_response    = time>=(t_peak-WINDOW_PEAK) & time<=(t_peak+WINDOW_PEAK);
    leak            = mean(resp(sel_baseline,:),1);
    response        = (mean(resp(sel_response,:),1) - leak)';
    sel_slope = find(time>=(t_onset + SLOPE_PT - WINDOW_PEAK) & time<=(t_onset + SLOPE_PT + WINDOW_PEAK));
    % this is the correct way to calculate the average slope
    t_slope   = (time(sel_slope) - t_onset) * 1000;
    % slope   = resp(sel_slope,:) - repmat(leak,size(sel_slope,1),1);
    % slope   = mean(slope ./ repmat(t_slope,1,size(leak,2)),1);
    % slope   = slope';
    % this is fudgy and fast and good enough for the kind of girls I go out
    % with:
    slope     = (mean(resp(sel_slope,:),1) - leak)';
    slope     = slope ./ mean(t_slope);
    leak            = leak';
    if ~isCC
        response    = -response;
        slope       = -slope;
    end
    
    % the mean event is packaged up for later fun, though setting the
    % number of points to extract is tricksy...
    %sel_trace       = time>(t_onset(ifile)-WINDOW_BASELN) & time < STIM_VISUAL;
    sel_trace       = time >= -0.1 & time <= 0.5;
    sel_trace_bl    = time>(t_onset-WINDOW_BASELN) & time < t_onset;
    trace           = avg(sel_trace) - mean(avg(sel_trace_bl));
    filttrace       = filtavg(sel_trace) - mean(filtavg(sel_trace_bl));
    time_trace      = time(sel_trace);
else
    leak        = [];
    response    = [];
    slope       = [];
    trace       = [];
    filttrace   = [];
    time_trace  = [];
end

%%% now calculate IR and SR
[ir, sr, t_sr, t_ir]    = computeResistance(R, ind_resist, isCC, time(1));

writefigure(fig, dd, WRITE_FIGURES, DEBUG_LOC);
warning on MATLAB:divideByZero
units   = R.y_unit{1};
% package in a structure
at              = R.abstime(:);
results = struct('ampl',response,'slope',slope,'ir',ir,'sr',sr,'leak',leak,...
    'time',at,'ampl_units',units,'slope_units',[units '/ms'],...
    'start',R.start_time,'trace',trace,'filttrace',filttrace,'time_trace',time_trace,...
    't_peak',num2cell(t_peak),'t_onset',num2cell(t_onset),'t_sr',t_sr,...
    't_ir',t_ir,'stim_electrical',iselectrical,'stim_start',-time(1),...
    'mode_currentclamp',isCC);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [t_onset, t_peak, filtavg] = findEvents(avg, time, Fs, times, isCC, isElec, WINDOW_RESP)
% this function finds the onset and peak times for the response (or tries
% to, anyway)
FILTER_ELEC     = 200;      % lowpass cutoff for electrical
FILTER_VIS      = 100;      % lowpass cutoff for finding peak of response
FILTER_ORDER    = 3;
THRESH_ONSET    = 3;        % X standard deviations away from mean defines onset
LENGTH_VIS      = 0.040;    % events must be at least 20 ms long
LENGTH_ELEC     = 0.010;    % electrical thresh can be lower
ARTIFACT_WIDTH  = 0.0015;   % width of the artifact to cut out for certain analyses
t_onset         = [];
t_peak          = [];
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
if ~isElec
    fp              = FILTER_VIS;
    LENGTH_EVENT    = LENGTH_VIS;
    filtavg         = filterresponse(avg,fp,FILTER_ORDER,Fs);
else
    fp              = FILTER_ELEC;
    THRESH_ONSET    = THRESH_ONSET * 0.66; % this may be a bad idea
    LENGTH_EVENT    = LENGTH_ELEC;
    sel_artifact    = time>-ARTIFACT_WIDTH & time < ARTIFACT_WIDTH;
    in              = avg;
    in(sel_artifact)    = deal(mu);  % this isn't perfect but it's easy
    filtavg     = filterresponse(in,fp,FILTER_ORDER,Fs);
end
h               = plot(time,filtavg,'k:');
legend('Response',sprintf('Filtered (%4.0f Hz)',fp));

% all the hard work gets skipped if the user specifies times
if ~isempty(times)
    t_onset         = times(1);
    t_peak          = times(2);    
else
    if isCC
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
    if isempty(above)
        return
    end
    diffabove       = diff(above);
    evbegs          = above([ 1; find(diffabove>1)+1 ]);
    evends          = above([ find(diffabove>1); length(above) ])+1;
    % eliminate events that are too long or short
    select          = (evends-evbegs)>=(LENGTH_EVENT * Fs);
    evtimes         = evbegs(select);
    if isempty(evtimes)
        return
    end
    t_onset     = time(evtimes(1));
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

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ir, sr, t_sr, t_ir] = computeResistance(R, ind_resist, isCC, t_offset)
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
if ~isCC
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
    
    t_sr         = r_time(fix(median(ind_trans))) + t_offset;
    if ~isempty(IR) & ~all(isnan(IR))
        ir           = IR(:);
        t_ir         = r_time([ind_baseline(1) ind_baseline(end),...
                               ind_ir(1) ind_ir(end)]) + t_offset;
        vline(t_ir);
    else
        ir       = [];
        t_ir     = [];
    end
else
    % to do: write analysis for current clamp
    ir         = [];
    sr         = [];
    t_sr       = [];
    t_ir       = [];
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

function [] = writeparameters(pre, pst)
% stores the timing data in some nice parameters
n   = 1;
for i = 1:length(pre)
    if ~isempty(pre(i).t_onset) & ~isempty(pre(i).t_peak)
        % mark time has to be adjusted for start of episode, not stimulus
        marks        = [pre(i).t_onset pre(i).t_peak] + pre(i).stim_start;
        params(n)    = struct('marks',marks,...
                         'name',sprintf('Pre %d', i),...
                         'action','-difference',...
                         'binning',0,...
                         'channel',1);
        n       = n + 1;
     end
end
for i = 1:length(pst)
    if ~isempty(pst(i).t_onset) & ~isempty(pst(i).t_peak)
        marks        = [pst(i).t_onset pst(i).t_peak] + pst(i).stim_start;
        params(n)    = struct('marks',marks,...
                         'name',sprintf('Post %d', i),...
                         'action','-difference',...
                         'binning',0,...
                         'channel',1);
        n       = n + 1;
     end
end
% ignore the IR and SR parameters for now, as episodeanalysis can't handle
% the 4-mark parameters
% write to disk
fn  = fullfile(pwd,'auto.p0');
save(fn,'params','-mat');

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