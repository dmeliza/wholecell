function [med, var, n, sptimes] = AutoAnalyzeSpikeTiming(data_dir, fid)
% Part of the AutoAnalyze suite.  Analyzes the induction period to
% determine the spike timing.
%
% [med, var, n, sptimes] = AutoAnalyzeSpikeTiming(data_dir, [fid])
%
% Loads the r0 file from DATA_DIR, and detects spikes by subtracting
% individual traces from the average trace, passing the difference traces
% through a highpass filter, and looking for threshhold crossings.  The
% threshhold can be tricky to set because the subtraction step can generate
% "negative spikes" for failures.  Returns the spike time median, variance,
% number, and distribution.
% 
% $Id$

THRESH_ELEC     = 20;
WINDOW_RESP     = 0.5;      % no data past this is analyzed for the response
STIM_VISUAL     = 0.2;      % start time for visual stimulation
THRESH_SPIKE    = 15;       % in mV, this is tricky because it will tend to pick
                            % out "negative" spikes (rebound from depol)
LENGTH_SPIKE    = [0.001 0.004];    % spikes in this length range (in seconds)
DEBUG           = 0;

error(nargchk(1,3,nargin));
if nargin < 2
    fid = 1;
end

curdir  = pwd;
cd(data_dir);

d   = dir('*.r0');
dd  = {d.name};
if length(dd) ~= 1
    fprintf(fid,'Induction directory must contain only one r0 file!\n');
    return
end
[R, str] = LoadResponseFile(dd{1});
if isempty(R)
    fprintf(fid,'Error loading %s\n', dd{1});
    return
end

% first determine if episodes need to be realigned (electrical)
ind_resp    = find(R.time <= WINDOW_RESP);
avg         = mean(R.data,2);
z           = zscore(diff(avg(ind_resp)));
if max(z) >= THRESH_ELEC
    iselectrical = 1;
else
    iselectrical = 0;
end
% align episode times
if iselectrical
    fprintf('Aligning traces...\n')
    [resp,time]    = AlignEpisodes(double(R.data),double(R.time),ind_resp);
    avg            = mean(resp,2);
else
    resp           = double(R.data);
    time           = double(R.time) - STIM_VISUAL;
end
% now comes the fun part.  Find spikes.
% the tricky bit is that there are up to three events fast enough to be
% confused for a spike.  The artifact, the voltage step from the current
% injection, and an actual spike.  We can take advantage of the jitter in
% spike timing to eliminate the constant events by subtracting the average.
clean_resp      = resp  - repmat(avg,1,size(resp,2));
% highpass filter to remove any slow residuals
clean_resp      = filterresponse(clean_resp, 1000, 3, R.t_rate);
% our sparse array of spike times
spikes = sparse([],[],[],size(resp,1),size(resp,2),1000);
% cycle through each trial
for i = 1:size(resp,2)
    % threshhold potentials
    threshed    = clean_resp(2:end-1,i) >= THRESH_SPIKE;
    above       = find(threshed);
    if any(above)
        diffabove   = diff(above);
        spbegs  = above([ 1; find(diffabove>1)+1 ]);
        spends  = above([ find(diffabove>1); length(above) ])+1;
        % eliminate events that are too long or short
        select  = (spends-spbegs)<=(LENGTH_SPIKE(2)*R.t_rate) & ...
                  (spends-spbegs)>=(LENGTH_SPIKE(1)*R.t_rate);
        sptimes = fix((spends(select) + spbegs(select))/2);
        if any(sptimes)
            spikes(sptimes,i) = ones(size(sptimes));
        end
    end
end
% figure out the statistics of the spike times
[sptime,sptrial]    = find(spikes);
timepdf     = full(sum(spikes,2));
if DEBUG
    % plot a useful thing
    thresh  = find(timepdf ~= 0);
    mn      = min(thresh);
    mx      = max(thresh);
    cdf     = cumsum(timepdf);
    figure,plot(time,resp);
    hold on
    h(1)    = plot(time,cdf,'k');
    set(h,'LineWidth',2);
    h(2)    = hline(THRESH_SPIKE);
    legend(h,'Cumulative spike count','Threshhold');
    set(gca,'XLim',[time(mn)-0.010, time(mx)+0.010])
    % save figure here...
end
sptimes     = time(sptime);

mu          = mean(sptimes);
med         = median(sptimes);
sigma       = std(sptimes);
n           = length(sptimes);
fprintf(fid,'Spike timing: %3.2f +/- %3.2f (%d)\n', med * 1000, sigma * 1000, n);

cd(curdir)

function out = filterresponse(data, cutoff, order, Fs)
% from Matteo Carandini's findspikes.m
deltat = 1/Fs;
tau = 1/cutoff;
b   = [ 1-(deltat/tau)^2 2*(deltat-tau)/tau ((deltat-tau)/tau)^2];
a   = [ 1 2*(deltat-tau)/tau ((deltat-tau)/tau)^2];
out = filter(b,a,data);     % the causal filter works okay here