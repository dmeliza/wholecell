function out = ComputeFilter(lag)
% [out.filt, out.stimulus, out.resp, out.Fs]  = ComputeFilter(lag)
%
% computes temporal filter from stimulus and response data
% loads data from .daq and .mat files in the directory
%
%
% 1.5: Complete rework
% $Id$

error(nargchk(1,1,nargin))

% load response data
if exist('daqdata-cat.mat','file') > 0
    d = load('daqdata-cat.mat');
    disp('Response loaded from daqdata-cat.mat');
else
    d = daq2mat('cat');
end
resp = double(d.data(:,1));
Fs_resp = d.info.t_rate;
clear('d');
% load stimulus data
if exist('daqdata-stim.mat','file') > 0
    d = load('daqdata-stim.mat');
    stim = d.stim;
    Fs_stim = d.Fs_stim;
    disp('Stimulus loaded from daqdata-stim.mat');
else
    stim = [];
    d = dir('*.daq');
    names = {d.name};
    for i = 1:length(names);
        [pn fn ext] = fileparts(names{i});
        f = load(fullfile(pn,[fn '.mat']));
        stim = cat(1,stim, f.stimulus);
        disp([fn '.mat: ' num2str(length(stim))]);
    end
    Fs_stim = f.stimrate;
    save('daqdata-stim.mat', 'stim', 'Fs_stim');
end
clear('d');
% There is a slight delay between when the data acquisition starts
% and the first stimulus value takes effect.  Synchronization relies
% on the first stimulus artifact, which appears as a sharp (~ 1 ms)
% click in the response.  The response is offset to the peak of the first
% click and then decimated to the frame rate.
r = resp(1:fix(0.05*Fs_resp));
var = abs((r - mean(r))/std(r));
[m i] = max(var);
resp = resp(i(1):end);
resp = bindata(resp,fix(Fs_resp/Fs_stim));
% Response conditioning: the basal leak current can shift significantly during
% an experiment.  A 0.1 Hz stop-band butterworth filter eliminates this
% quite nicely (designed elsewhere)
num = [0.9412 -0.9412];
den = [1 -0.8823];
resp = filtfilt(num,den,resp);

% compute the filter and return the values.  No correction should be necessary
% as the input will have no auto-correlation.
options.correct = 'no';
h1_est = danlab_revcor(stim(1:length(resp)),resp,lag*Fs_stim/1000,Fs_stim,options);
out.filt = h1_est;
out.resp = resp;
out.stim = stim(1:length(resp));


% if isa(varargin{1},'char')
%     filename = varargin{1};
%     window = varargin{2};
%     r_file = [filename '.daq'];
%     s_file = [filename '.mat'];
% 
%     if exist(r_file,'file') == 0
%         error([r_file ' does not exist.']);
%     end
%     info = daqread(r_file,'info');
%     samplerate = info.ObjInfo.SampleRate;
%     stimstart = info.ObjInfo.InitialTriggerTime;
%     [data, time, datastart] = daqread(r_file);
%     response = data(:,1);
% 
%     if nargin == 3
%         stimchannel = varargin{3};
%         stimrate = samplerate;
%         stimulus = data(:,stimchannel);
%     elseif exist(s_file,'file') ~= 0
%         info = load(s_file);
%         stimrate = info.stimrate;
%         stimulus = info.stimulus;
%     else
%         error([s_file ' does not exist.']);
%     end
% else
%     stimulus = varargin{1};
%     response = varargin{2};
%     window = varargin{3};
%     samplerate = varargin{4};
%     stimrate = samplerate;
%     if length(stimulus) ~= length(response)
%         error('Stimulus and response must be same length');
%     end
% end
% 
% c = RevCorr(response, stimulus, samplerate, stimrate,...
%     stimstart, datastart, window);
% 
% f = c(fliplr(1:length(c)));
% sr = 1000 / stimrate;
% t = 0:sr:(-window(1));
% if nargout == 0
%     figure,plot(t,f);
%     xlabel('Time (ms)');
% else
%     filt = f;
% end
% 
% resp = bindata(response, samplerate / stimrate);
% if nargout == 0
%     checkfilter(stimulus, resp, f, sr);
% end
% m = 5 * Fs_stim;
% n = floor(length(resp)/m);
% r = reshape(resp(1:m*n), m, n);
% offset = repmat(mean(r,1),m,1);
% r = reshape(r - offset, m*n, 1);