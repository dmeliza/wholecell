function varargout = FlashEpisode(varargin)
%
% This basic protocol acquires episodes from the amplifier and
% records the response to stimulation.  Two different stimulation channels
% are available: one is the DAQ board and the other is the video card.
% Thus, it is possible with this protocol to both flash an image and
% shock the preparation.

% Implementation of the flash is tricky for two reasons: we have to use the timer
% to start the flash at the right time, and because of the refresh rate of the
% display there will probably be jitter on the order of a frame in the timing
% of the stimulus.  Thus it's probably a good idea to also record something like
% a photocell to know when the screen goes off.
%
% Alternative implementation: use cglib's playmovie function
% Alt impl 2: trigger acquisition off a photocell signal
%
% Issues as of 1.1:
% Timing of flash is imprecise and inaccurate (from 182 ms to 204 ms)
% Length of flash varies (by up to 4 integral multiples of frame length) (v. bad)
% Change in luminance at beginning of each episode (solved - photocell V depends on load)
% On and off timecourses are different (but this might be a photocell issue)
%
% 1.4:
% Using matlab's timer decreases frame shift errors in length but increases
% jitter in start time. Because post-acq alignment can correct for start time
% errors pretty well (concurrent changes in AlignEpisodes to support this operation)
% this is a preferable (but not optimal--how to pair current injection, e.g.)
% situation.  Also there is a pretty significant but systematic increase in the
% lag between start of episode and flash onset, about 70 ms.  Onset delay is
% probably caused by a variable amount of execution time between the start of
% data logging and the execution of the timer or trigger callback (and specifically
% the cgflip command)
%
% 1.5:
% The triggering scheme is complicated because we need to synchronize
% data acquisition and output with the frame rate of the video system.
% Thus, there must be a photocell placed on the monitor that can detect the
% flash.  Time=0 will be when the hardware detects a rising edge in this signal.
% Pretriggering allows us to record input signals before the trigger, so
% a baseline can be accurately measured.  Consequently, ai and ao must be started
% (but not triggered), and then the video subroutine started.  Currently this
% uses matlab's timer, but other implementations may work better.
%
% An unfortunate side effect is that the flash must be the first event (in terms
% of output) because it is impossible to send data to the analog out *after* the
% trigger has occurred.  Furthermore, analog output devices can't be triggered
% off analog input signals (only digital, but I don't want to implement that except
% as a last resort), so the analog input has to have a callback on *its* trigger
% to start the output.  This may lead to jitters in the timing of AO events.
%
% 1.7:
% Attempts to eliminate jitter: use timer to trigger turning off image
% This works great *if* you pick a duration that isn't close to a multiple of the
% frame rate (e.g. 200, 300, 400 ms for 60 Hz).  If you want a 300 ms flash, pick
% 292 ms (300 ms minus half the frame rate)
%
% $Id$

global wc

if isobject(varargin{1})
    feval(varargin{3},varargin{1:2});
    return;
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
    Scope('init');
    
    EpisodeStats('init','min','','PSR_IR');
    
case 'start'
    setupHardware;
    setupScope;
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    set(wc.ai,'LogFileName',fullfile(dir, '0000.daq'));
    EpisodeStats('clear');
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        Episode('stop');
    end
    setupHardware;
    setupScope;

    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    EpisodeStats('clear');
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));    
    
case 'stop'
    ClearAO(wc.ao);
    if (isvalid(wc.ai))
        stop(wc.ai);
        set(wc.ai,'SamplesAcquiredAction',{});
        set(wc.ai,'LoggingMode','Memory');
        SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
        set(wc.ai,'LogFileName',NextDataFile);
    end

case 'close_callback'
    delete(gcbf);
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = defaultParams;
global wc;
f = {'description','fieldtype','value','units'};
f_s = {'description','fieldtype','value'};
f_l = {'description','fieldtype','value','choices'};
loadStim = @loadStimulus;

p.inj_length = cell2struct({'Inj Length','value',6,'ms'},f,2);
p.inj_delay = cell2struct({'Inj Delay','value',200,'ms'},f,2);
p.inj_gain = cell2struct({'Inj Gain','value',1},f_s,2);
p.inj_channel = cell2struct({'Command','list',1,GetChannelList(wc.ao)},f_l,2);

p.vis_len = cell2struct({'Visual Length','value', 300, 'ms'},f,2);
p.vis_delay = cell2struct({'Visual Delay','value', 200, 'ms'},f,2);
p.vis_image = cell2struct({'Visual Image','fixed','',loadStim},...
    {'description','fieldtype','value','callback'},2);
p.vis_disp = cell2struct({'Display', 'value', 2},f_s,2);
p.sync_val = cell2struct({'Sync Voltage','value',2,'V'},f,2);
p.sync_c = cell2struct({'Sync Channel','list',1,GetChannelList(wc.ai)},f_l,2);

p.stim_len = cell2struct({'Stim Length','value', 300, 'ms'},f,2);
p.stim_delay = cell2struct({'Stim Delay','value',200,'ms'},f,2);
p.stim_gain = cell2struct({'Stim Gain','value',10,'(V)'},f,2);
p.frequency = cell2struct({'Ep. Freq','value',0.2,'Hz'},f,2);
p.ep_length = cell2struct({'Ep. Length','value',2000,'ms'},f,2);
p.stim_channel = cell2struct({'Stimulator','list',1,GetChannelList(wc.ao)},f_l,2);
p.input_channel = cell2struct({'Input','list',1,GetChannelList(wc.ai)},f_l,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
display = @updateDisplay;
% reset display
setupVisual;
% acq params
sr = get(wc.ai, 'SampleRate');
length = GetParam(me,'ep_length','value');
len = length * sr / 1000;
set(wc.ai,'SamplesPerTrigger',len)
set(wc.ai,'SamplesAcquiredActionCount',len)
set(wc.ai,'SamplesAcquiredAction',{me, display}) 
set(wc.ai,'ManualTriggerHwOn','Start');
set(wc.ao,'SampleRate', 1000)
% hardware triggering:
sync = GetParam(me,'sync_c','value');
sync_v = GetParam(me,'sync_val','value');
sync_off = GetParam(me,'vis_delay','value') / 1000;
curr = getsample(wc.ai);
curr = curr(sync); % current value of sync detector
ao_sync = @aoTrigger;
set(wc.ai,'TriggerDelayUnits','seconds');
set(wc.ai,'TriggerDelay',-sync_off);
set(wc.ai,'TriggerType','Software');
set(wc.ai,'TriggerCondition','Rising');
set(wc.ai,'TriggerConditionValue',curr+sync_v);
set(wc.ai,'TriggerChannel',wc.ai.Channel(sync));
set(wc.ai,'TriggerAction',{me,ao_sync});

function setupVisual()
% visual output: the stimulus file has four fields:
% xres, yres - the dimensions of the image
% stim - the values for each pixel
% colmap - the colormap
disp = GetParam(me,'vis_disp','value');
cgloadlib;
cogstd('spriority','high');
cgshut;
cgopen(5,8,85,disp);
stimfile = GetParam(me,'vis_image','value');
s = load(stimfile);
cgcoltab(0,s.colmap);
cgnewpal;
cgloadarray(1,s.xres,s.yres,s.stim,s.colmap,0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function queueStimulus()
% populates the wc.ao data channels.  We can only output data after
% the flash trigger has gone off, so the length of the output data is
% episode length - visual delay, and delay times must be offset by the
% visual delay.
global wc

len = GetParam(me,'ep_length','value'); %ms
trigger_delay = GetParam(me,'vis_delay','value'); %ms
dt = 1000 / get(wc.ao,'SampleRate'); %ms/sample
len = len - trigger_delay;
p = zeros(len / dt, length(wc.ao.Channel));
% stimulator
ch = GetParam(me,'stim_channel','value');
del = (GetParam(me,'stim_delay','value') - trigger_delay) / dt; %samples
i = del+1:(del+ GetParam(me,'stim_len','value'));
p(i,ch) = GetParam(me,'stim_gain','value');
% injection
ch = GetParam(me,'inj_channel','value'); 
del = (GetParam(me,'inj_delay','value') - trigger_delay) / dt; %samples
dur = GetParam(me,'inj_length','value') / dt; %samples
gain = GetParam(me,'inj_gain','value');
i = del+1:del+dur;
p(i,ch) = gain;
putdata(wc.ao,p);
% visual: setup event callback and load the flash frame into video memory
stim_off = @imageOff;
gprimd = cggetdata('gpd');
cgdrawsprite(1,0,0, gprimd.PixWidth, gprimd.PixHeight)
dur = GetParam(me,'vis_len','value') / 1000; % s
set(wc.ai,'TimerPeriod', dur);
set(wc.ai,'TimerAction', {me,stim_off}); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function loadStimulus(varargin)
mod = varargin{3};
param = varargin{4};
s = varargin{5};
t = [mod '.' param];
h = findobj(gcbf,'tag',t);
v = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2] = uigetfile([pn filesep '*.mat']);
if ~isnumeric(fn2)
    v = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s = SetParam(mod, param, v);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function stim = getStimulus(filename)
% loads a mat file and returns the first (numeric) variable in the file
d = load(filename);
n = fieldnames(d);
if length(n) < 1
    error('No data in stimulus file');
end
stim = getfield(d,n{1});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imageOn()
% gets called for each episode. waits delay and flips
% display for duration (which is what triggers acquisition)
del = GetParam(me,'vis_delay','value'); % ms
pause(del/1000);
cgflip(0);

function imageOff(obj,event)
% turns off stimulus
cgflip(0);
set(obj,'TimerAction',{});

function aoTrigger(obj,event)
% triggers the analog output
global wc
trigger(wc.ao);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function updateDisplay(obj, event)
% plots and analyzes the data
[data, time, abstime] = getdata(obj);
plotData(data, time, abstime);
t = 1 / GetParam(me,'frequency','value');
t2 = GetParam(me,'ep_length','value') / 1000;
pause(t - t2)
l = get(obj,'SamplesAcquiredAction');
if ~isempty(l)
    startSweep;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotData(data, time, abstime)
% plots the data

scope = getScope;
mode = GetParam('control.telegraph', 'mode');
gain = GetParam('control.telegraph', 'gain');
index = GetParam(me,'input_channel','value');
if ~isempty(mode)
    units = TelegraphReader('units',mean(data(:,mode)));
else
    units = 'V';
end
if ~isempty(gain)
    gain = TelegraphReader('gain',mean(data(:,gain)));
else
    gain = 1;
end
lbl = get(scope,'YLabel');
set(lbl,'String',['amplifier (' units ')']);
% plot the data and average response
data = AutoGain(data(:,index), gain, units);
a = get(scope, 'UserData'); % avgdata is now a cell array
if isempty(a)
    numtraces = 1;
    avgdata = data;
else
    avgdata = a{2};
    numtraces = a{1} + 1;
    avgdata = avgdata + (data - avgdata) / (numtraces);
end
Scope('plot','plot',time * 1000, [data avgdata]);
a = {numtraces, avgdata};
set(scope,'UserData', a);
EpisodeStats('plot', abstime, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupScope();
% sets up the scope properties
scope = getScope;
clearPlot;
set(scope, 'XLim', [0 1000]);
set(scope, 'NextPlot', 'replacechildren');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('scope','status','String',get(wc.ai,'logfilename'));
queueStimulus;
start([wc.ai wc.ao]);
imageOn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot()
Scope('clear')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function scope = getScope()
scope = GetUIHandle('scope','scope');
if (isempty(scope) | ~ishandle(scope))
    Scope('init');
    scope = GetUIHandle('scope','scope');
end