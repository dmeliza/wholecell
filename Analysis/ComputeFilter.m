function [filt, stimulus, resp] = ComputeFilter(filename, window, stimchannel)
%
% computes temporal filter from stimulus and response data
% if stimchannel is supplied, this is used instead of the .mat file
% use a window of [0 0] to get all points
%
% $Id$

error(nargchk(2,3,nargin))
error(nargoutchk(0,3,nargout))

r_file = [filename '.daq'];
s_file = [filename '.mat'];

if exist(r_file,'file') == 0
    error([r_file ' does not exist.']);
end
info = daqread(r_file,'info');
samplerate = info.ObjInfo.SampleRate;
stimstart = info.ObjInfo.InitialTriggerTime;
[data, time, datastart] = daqread(r_file);

if nargin == 3
    stimrate = samplerate;
    stimulus = data(:,stimchannel);
elseif exist(s_file,'file') ~= 0
    info = load(s_file);
    stimrate = 1000 / info.time_resolution;
    stimulus = info.stimulus;
else
    error([s_file ' does not exist.']);
end

c = RevCorr(data(:,1), stimulus, samplerate, stimrate,...
    stimstart, datastart, window);

f = c(fliplr(1:length(c)));
sr = 1000 / stimrate;
t = 0:sr:(-window(1));
if nargout == 0
    figure,plot(t,f);
    xlabel('Time (ms)');
else
    filt = f;
end

resp = bindata(data(:,1), samplerate / stimrate);
if nargout == 0
    checkfilter(stimulus, resp, f, sr);
end
