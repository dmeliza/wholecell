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

% analyze first directory
curdir  = pwd;
cd(pre_dir);
if nargin > 3
    pre     = analyzedirectory(fid, t_pre);
else
    pre     = analyzedirectory(fid, []);
end
cd(curdir)
if isempty(pre)
    return
end

% analyze second directory
if nargin > 1
    cd(post_dir)
    if nargin > 4
        pst   = analyzedirectory(fid, t_post);
    else
        pst   = analyzedirectory(fid, []);        
    end
    if ~isempty(pst)
        printresults(fid,pre,pst)
    else
        printresults(fid,pre);
    end
    cd(curdir)
else
    pst = [];
    printresults(fid,pre)
end

function [] = printresults(fid, pre, pst)
% print responses for each stimulus condition
for i = 1:length(pre)
    if nargin > 2
        printdifference(fid, sprintf('R%d: (%3.0f -> %3.0f ms)',i,...
            pre(i).t_peak*1000,pst(i).t_peak*1000),...
            pre(i).resp, pst(i).resp, pre(i).units);
        fprintf(fid,' (%3.1f ; %3.1f %s)\n',...
                pre(i).time(end) - pre(i).time(1),...
                pst(i).time(end) - pst(i).time(1), 'min');
    else
        n   = sqrt(length(pre(i).resp));
        len = pre(i).time(end) - pre(i).time(1);
        fprintf(fid,'R%d: (%3.0f ms) %3.2f +/- %3.2f %s (%3.1f %s)\n', i, ...
            pre(i).t_peak * 1000, mean(pre(i).resp), std(pre(i).resp)/n, pre(i).units,...
            len, 'min');
    end
end
% calculate SR and IR for all stimulus conditions
pre_ir      = cat(1,pre.ir);
pre_sr      = cat(1,pre.sr);
n           = sqrt(size(pre_ir,1));
fprintf(fid,'----\n');
if nargin > 2
    pst_ir  = cat(1,pst.ir);
    pst_sr  = cat(1,pst.sr);
    printdifference(fid, 'IR:', pre_ir, pst_ir, pre(1).units);
    fprintf('\n');
    printdifference(fid, 'SR:', pre_sr, pst_sr, pre(1).units);    
    fprintf('\n');
else
    fprintf(fid,'IR: %3.2f +/- %3.2f %s\n',...
        mean(pre_ir), std(pre_ir)/n, pre(1).units);
    fprintf(fid,'SR: %3.2f +/- %3.2f %s\n',...
        mean(pre_sr), std(pre_sr)/n, pre(1).units);     
end

function [] = printdifference(fid, name, pre, post, units)
[h,p]       = ttest2(pre,post);
pre_m       = mean(pre);
pst_m       = mean(post);
fprintf(fid, ['%s %3.2f +/- %3.2f -> %3.2f +/- %3.2f %s (%3.1f%%; P = %3.4f)'],...
    name, pre_m, std(pre)/sqrt(length(pre)), pst_m,...
    std(post)/sqrt(length(post)), units, pst_m/pre_m * 100 - 100, p)


function [results] = analyzedirectory(fid, times);
% this function does all the work of analyzing the directory
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS

results         = [];
THRESH_ELEC     = 20;
WINDOW_RESP     = 0.5;      % no data past this is analyzed for the response
STIM_VISUAL     = 0.2;      % start time for visual stimulation
DO_FILTER       = 1;
FILTER_LP       = 1000;     % lowpass filter cutoff (Hz)
FILTER_ELEC     = 200;      % lowpass cutoff for electrical
FILTER_VIS      = 50;      % lowpass cutoff for finding peak of response
FILTER_ORDER    = 3;
THRESH_ONSET    = 3;        % X standard deviations away from mean defines onset
WINDOW_BASELN   = 0.05;     % length of the baseline to use in computing the response
WINDOW_PEAK     = 0.001;    % amount of time on either side of the peak to use
ARTIFACT_WIDTH  = 0.0015;   % width of the artifact to cut out for certain analyses
DEBUG_LOC       = 0;

d   = dir('*.r0');
dd  = {d.name};
for ifile = 1:length(dd)
    % load the r0 file, using the accompanying selector file if needed
    [R, str]    = LoadResponseFile(dd{ifile});
    if isempty(R)
        error(str)
    end
    ind_resp    = find(R.time <= WINDOW_RESP);
    ind_resist  = find(R.time > WINDOW_RESP);
    avg         = mean(R.data,2);
    % pre-process the file
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
        fprintf('Aligning traces...\n')
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
            fp          = FILTER_VIS;
            filtavg     = filterresponse(avg,fp,FILTER_ORDER,R.t_rate);
        else
            fp          = FILTER_ELEC;
            sel_artifact= time>-ARTIFACT_WIDTH & time < ARTIFACT_WIDTH;
            in          = avg;
            in(sel_artifact)    = deal(mu);  % this isn't perfect but it's easy
            filtavg     = filterresponse(in,fp,FILTER_ORDER,R.t_rate);
        end
        h               = plot(time,filtavg,'k:');
        legend('Response',sprintf('Filtered (%4.0f Hz)',fp));
    if isempty(times)
        
        if iscurrentclamp
            ind             = find(filtavg > (mu + sigma * THRESH_ONSET) & t_sel);
            hline(mu + sigma * THRESH_ONSET,'r:');
        else
            ind             = find(filtavg < (mu - sigma * THRESH_ONSET) & t_sel);
            hline(mu - sigma * THRESH_ONSET,'r:');
        end
        % see if we can find an event onset - this usually fails when there are
        % too few traces, so we return an empty results structure
        if isempty(ind)
            fprintf(fid, 'Err: Unable to detect event onset\n');
            return
        end
        t_onset(ifile)   = time(ind(1));
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
        t_sel           = time>=t_onset(ifile) & time<=WINDOW_RESP;
        ind             = find(diff(filtavg) >= 0 & t_sel(2:end));
        t_peak(ifile)   = time(ind(1));
    else
        t_onset         = times(:,1);
        t_peak          = times(:,2);
    end
    vline(t_onset(ifile),'k:')
    vline(t_peak(ifile),'k')    
    % and now we can actually compute the response
    sel_baseline    = time<t_onset(ifile) & time>(t_onset(ifile)-WINDOW_BASELN);
    if iselectrical
        sel_artifact= time>-ARTIFACT_WIDTH & time < ARTIFACT_WIDTH;
        sel_baseline= sel_baseline & ~sel_artifact;
    end
    sel_response    = time>=(t_peak(ifile)-WINDOW_PEAK) & time<=(t_peak(ifile)+WINDOW_PEAK);
    baseline        = mean(resp(sel_baseline,:),1);
    response{ifile}   = (mean(resp(sel_response,:),1) - baseline)';
    if ~iscurrentclamp
        response{ifile}  = -response{ifile};
    end
    at{ifile}       = R.abstime(:);
    % the mean event is packaged up for later fun, though setting the
    % number of points to extract is tricksy...
    sel_trace       = time>(t_onset(ifile)-WINDOW_BASELN) & time < STIM_VISUAL;
    trace           = filtavg(sel_trace);
    time_trace      = time(sel_trace);
    
    % now calculate IR and SR
    % we need to use unfiltered, unaligned data to ensure the transients
    % line up
    resp            = double(R.data(ind_resist,:));
    time            = time(ind_resist);
%    time            = double(R.time(ind_resist));
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
        sr{ifile}     = -m(:);
        ind_trans       = i + offset;
        [m,i]           = max(filtresp,[],1);
        ind_trans2      = i;
        for i = 1:size(resp,2)
            ind_baseline    = [1:300] - 400 + ind_trans(i);
            ind_ir          = fix((ind_trans2(i) + ind_trans(i))/2);
            ind_ir          = [ind_ir:ind_trans2(i)-100];
            IR(i)           = mean(resp(ind_baseline,i),1) - mean(resp(ind_ir,i),1);
        end
        ir{ifile}           = IR(:);
        % extract approximate times for resistance measures
        t_sr{ifile}         = time(median(ind_trans));
        t_ir{ifile}         = time([ind_baseline(1) ind_baseline(end) ind_ir(1) ind_ir(end)]);
        vline(t_ir{ifile});
        if WRITE_FIGURES
            [pn,fn,ext]     = fileparts(dd{ifile});
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
    else
        % to do: write analysis for current clamp
        ir{ifile}  = [];
        sr{ifile}  = [];
    end
    warning on MATLAB:divideByZero
    units   = R.y_unit{1};
    % package in a structure (which turns the cell arrays into elements of
    % a structure array)
    results = struct('resp',response,'ir',ir,'sr',sr,'time',at,'units',units,...
        'start',R.start_time,'trace',trace,'time_trace',time_trace,...
        't_peak',num2cell(t_peak),'t_onset',num2cell(t_onset),'t_sr',t_sr,...
        't_ir',t_ir);
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