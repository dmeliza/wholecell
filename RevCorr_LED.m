function varargout = RevCorr_LED(varargin)
%
% RevCorr_LED: A protocol for use with the wholecell toolkit.  Control up to
% two LED's with varying degrees of correlation.  Intended for monocular
% or binocular full-field stimulation of an animal while recording.  The user can
% select the frame rate of each LED and a file or mfile that describes the time sequence
% of each LED's activity.
% 
% Online analysis uses xcorr to look for the first moment of the temporal filter.
%
% void RevCorr_LED(action)
%
% Input:  a file containing one or two column vectors which represent the state of
%         each LED over the course of the acquisition.  Or an mfile that dynamically
%         generates these sequences.
%
% Output: The DAQ toolkit is responsible for sending the voltages to the LED's through
%         the analogoutput object, and recording the response of the cell through
%         the analoginput object.
%
% Details: The operation of this protocol is quite straightforward.  The user specifies
%          a frame rate and an output sequence.  The sequence is loaded into the daq's
%          analog output, and when the user clicks "Start" or "Record", the ai and ao
%          objects are triggered simultaneously.  Empirically, although the DAQ toolbox
%          claims that this causes both objects to start simultaneously, this is not
%          always the case, so we do need a synchronization signal to make sure that
%          the stimulus and response are in frame.  This is done by feeding one of the
%          LED signals into a separate input. The ao is reset to 0 before starting, so
%          the data can be realigned based on when the sync signal transitions from 0
%          to either the ON or the OFF state.
%
%          Additional workarounds were introduced in 1.16+ to deal with the fact that
%          the DAQ routines "crash" if the sampling rate of the analog input and output
%          are significantly different.  This puts a lower limit on the frame rate of
%          the LED, around 100 Hz, which is much too high.  Consequently we have to upsample
%          the input sequence to a usable frame rate.
%
% $Id$

global wc

if isobject(varargin{1})
    feval(varargin{3},varargin{1:2});
    return
end

if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action

case {'init','reinit'}
    p = defaultParams;
    fig = ParamFigure(me, p);
    getScope;
    
case 'start'
    setupHardware;
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    set(wc.ai,'LogFileName',fullfile(dir, '0000.daq'));    
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));    
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        feval(me,'stop');
    end
    setupHardware;
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));    
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    
case 'stop'
    ClearAO(wc.ao);
    if (isvalid(wc.ai))
        stop(wc.ai);
        clearDAQ
    end
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function p = defaultParams()
global wc;

    f = {'description','fieldtype','value','units'};
    p.sequence = struct('description','Sequence','fieldtype','file_in',...
                        'value','');
    p.s_max.description = 'Max LED Voltage';
    p.s_max.fieldtype = 'value';
    p.s_max.units = 'V';
    p.s_max.value = 3.6;
    p.s_min.description = 'Min LED Voltage';
    p.s_min.fieldtype = 'value';
    p.s_min.units = 'V';
    p.s_min.value = 2.0;
    p.repeat = struct('description','Repeats (0=inf)','fieldtype','value',...
                      'value',1);
    p.f_rate = struct('description','Frame Rate','fieldtype','value',...
                     'units','Hz','value',20);
    c = GetChannelList(wc.ai);
    p.sync = struct('description','Sync Channel','fieldtype','list',...
                    'choices',{c},'value',1);
    p.input = struct('description','Amplifier Channel','fieldtype','list',...
                     'choices',{c},'value',1);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
analyze = @analyze;
srate   = get(wc.ai, 'SampleRate');               % sample rate of ai
frate   = GetParam(me,'f_rate','value');          % frame rate of LED in Hz
len     = loadStimulus;                           % number of frames
a_int   = (len + 4) / frate * srate;              % analysis interval, samples
delay   = 2 / frate * srate;                      % 2 frame delay

set(wc.ai,'SamplesPerTrigger',a_int);
set(wc.ai,'TriggerDelayUnits','samples');
set(wc.ai,'TriggerDelay',-delay);
set(wc.ai,'SamplesAcquiredActionCount',a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set([wc.ai wc.ao],'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Start');

% the frame rate of the ao must be greater than 100, but an
% integral multiple of the supplied frame rate.
m       = fix(200/frate);
rate    = (m+1) * frate;        % this ensures that we're more than 200
set(wc.ao, 'SampleRate', rate);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
queueStimulus(wc.ai,wc.ao);
start([wc.ai wc.ao]);
pause(0.1);
trigger([wc.ai wc.ao]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function len = loadStimulus()
% Loads the stimulus from the disk and stores it in the status UserData
seqf    = GetParam(me,'sequence','value');
seq     = loadSequence(seqf);
SetUIParam('protocolcontrol','status','UserData',seq);
len     = size(seq,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function [] = queueStimulus(ai, ao)
% queues data in the ao object
% also writes the stimulus to disk if the ai is in disk-logging mode
seq     = GetUIParam('protocolcontrol','status','UserData');
m = get(ai,'LoggingMode');
if ~strcmpi('memory',m)
    lf = get(ai,'Logfilename')
    writeStimulus(lf,seq);
end

% rescale sequence to voltages
minV    = GetParam(me,'s_min','value');
maxV    = GetParam(me,'s_max','value');
seq     = (seq - min(min(seq))) * (maxV - minV) / max(max(seq)) + minV;
frate   = GetParam(me,'f_rate','value');    % the real frame rate
aorate  = get(ao,'SampleRate');             % the sample rate of the ao, higher or equal to frate
m       = aorate/frate;

nchan   = length(ao.Channel);           % number of channels
seq     = upsample(seq,m,nchan);        % upsample the sequence

putsample(ao,zeros(1,nchan));           % reset output
putdata(ao,seq);                        % here is where the data gets sent to the ao obj

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seq = upsample(seq, mult, nchan)
% upsamples and pads/truncates the number of channels so that the sequence
% can be passed directly to the analogoutput. seq should be an array or column vector
[len n] = size(seq,1);
if n < nchan
    seq = [seq, zeros(len,nchan-n)];  % pad out channels
elseif n > nchan
    seq = seq(:,1:nchan);             % chop out useless channels
end
% upsample if necessary
if mult > 1
    seq     = permute(seq,[3 1 2]);
    seq     = repmat(seq,[mult 1 1]);
    seq     = reshape(seq,[len*mult nchan]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seq = loadSequence(filename)
% loads the sequence from a file, throwing errors when appropriate
if ~exist(filename)
    errordlg(['Sequence file does not exist']);
    error('Unable to load sequence file');
end
[pn fn ext] = fileparts(filename);
switch lower(ext)
case '.mat'
    seq = load(filename);
    fn  = fieldnames(seq);      % load first field
    seq = getfield(seq,fn{1});
case '.m'
    seq = feval(filename);
otherwise
    errordlg(['Invalid sequence file!']);
    error('Unable to load sequence from file');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeStimulus(filename, stimulus)
% writes stimulus waveform to a mat file for later analysis
frate = GetParam(me,'f_rate','value');
[pn fn ext] = fileparts(filename);
save([pn filesep fn '.mat'],...
    'stimulus', 'frate');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% this function is called when the full set of data has been acquired
% it collects data from the buffer, plots it, and calls the analysis method
% if there are additional repeats to run, it calls startSweep()
global wc
stop([obj wc.ao]);
lfn       = get(obj,'LogFileName');
[pn fn e] = fileparts(lfn);
if ~strcmp('memory',lower(get(obj,'LoggingMode')))
    save(fullfile(pn,[fn '-param']),'param');
end
plotResults(obj, wc.ao);
r         = GetParam(me,'repeat','value');
if r == 0 | r > str2num(fn)
    startSweep;
else
    ClearAI(obj);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotResults(ai, ao)
% this method plots and analyzes the data in the buffer
in      = GetParam(me,'input','value');
sync    = GetParam(me,'sync','value');
[data, time, abstime] = getdata(ai);
axes(getScope)
% align input and output timings
stim    = GetUIParam('protocolcontrol','status','UserData');
srate   = get(ai,'SampleRate');             % sample rate
frate   = GetParam(me,'f_rate','value')     % LED frame rate (real)
%frate   = get(ao,'SampleRate');            % LED frame rate (poss upsampled)
ini     = mean(data(1:100,sync));
ind     = find(data(:,sync)<ini*3);         % indices of data near minimum value
ind     = max(ind)+1;
data    = data(ind:end,in);
time    = time(ind:end);
plot(time,data);

% quick analysis using danlab_revcor
y       = bindata(data,srate/frate,1);      % bin response to frame rate
options = struct('correct','no','display','yes');
keyboard
kern    = danlab_revcor(stim,y(1:length(stim)),10,frate,options);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function a = getScope()
% retrieves the handle for the scope axes
f       = findfig([me '.scope']);
set(f,'position',[288 314 738 508],'name','scope','numbertitle','off');
a       = get(f,'Children');
if isempty(a)
    a   = axes;
    set(a,'NextPlot','ReplaceChildren')
    set(a,'XTickMode','Auto','XGrid','On','YGrid','On','YLim',[-5 5])
    xlabel('Time (ms)')
    ylabel('amplifier (V)')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clearDAQ()
% resets callbacks so we don't get recordings where we don't want'em
global wc
set(wc.ai,'SamplesAcquiredAction',{});
set(wc.ai,'TimerAction',{});
SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
set(wc.ai,'LoggingMode','Memory');
set(wc.ai,'LogFileName',NextDataFile);
set(wc.ai,'TriggerType','Manual')
set(wc.ai,'TriggerDelay',0);