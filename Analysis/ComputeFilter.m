function [filt, t, stimulus, resp] = ComputeFilter(varargin)
% ComputeFilter(filename, window, [stimchannel])
% ComputeFilter(stimulus, response, window, Fs)
%
% computes temporal filter from stimulus and response data
% if stimchannel is supplied, this is used instead of the .mat file
% use a window of [0 0] to get all points
%
%
% $Id$

error(nargchk(2,4,nargin))
error(nargoutchk(0,3,nargout))

if isa(varargin{1},'char')
    filename = varargin{1};
    window = varargin{2};
    r_file = [filename '.daq'];
    s_file = [filename '.mat'];

    if exist(r_file,'file') == 0
        error([r_file ' does not exist.']);
    end
    info = daqread(r_file,'info');
    samplerate = info.ObjInfo.SampleRate;
    stimstart = info.ObjInfo.InitialTriggerTime;
    [data, time, datastart] = daqread(r_file);
    response = data(:,1);

    if nargin == 3
        stimchannel = varargin{3};
        stimrate = samplerate;
        stimulus = data(:,stimchannel);
    elseif exist(s_file,'file') ~= 0
        info = load(s_file);
        stimrate = info.stimrate;
        stimulus = info.stimulus;
    else
        error([s_file ' does not exist.']);
    end
else
    stimulus = varargin{1};
    response = varargin{2};
    window = varargin{3};
    samplerate = varargin{4};
    stimrate = samplerate;
    if length(stimulus) ~= length(response)
        error('Stimulus and response must be same length');
    end
end

c = RevCorr(response, stimulus, samplerate, stimrate,...
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

resp = bindata(response, samplerate / stimrate);
if nargout == 0
    checkfilter(stimulus, resp, f, sr);
end
