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
% 1.21:
% Some changes implemented in order to take advantage of TTL triggering.  On the one
% hand, TTL signals can be used to trigger both analog input and output, allowing everything
% to be nicely synchronized; on the other, no preacquisition is available with hardware
% triggers, so we have to implement this manually by sending a signal to the photocell
% when we want acquisition to actually start.  We're still using pause() calls, which can
% be jittery.
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
    CGDisplay(action)
    p = defaultParams;
    fig = findobj('tag',[lower(me) '.param']);        % checks if the param window is already
    if isempty(fig)                                   % open
        fig = ParamFigure(me, p);
    end
    getScope;
    EpisodeStats('init','min','','PSR_IR');
    
case 'start'
    setupHardware;
    clearScope;
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
    clearScope;
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
    ClearAI(wc.ai);

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
f        = {'description','fieldtype','value','units'};
f_s      = {'description','fieldtype','value'};
f_l      = {'description','fieldtype','value','choices'};
loadStim = @loadStimulus;

p.inj_length  = cell2struct({'Inj Length','value',6,'ms'},f,2);
p.inj_delay   = cell2struct({'Inj Delay','value',200,'ms'},f,2);
p.inj_gain    = cell2struct({'Inj Gain','value',1},f_s,2);
p.inj_channel = cell2struct({'Command','list',1,GetChannelList(wc.ao)},f_l,2);

p.vis_len     = cell2struct({'Visual Length','value', 300, 'ms'},f,2);
p.vis_delay   = cell2struct({'Visual Delay','value', 200, 'ms'},f,2);
p.vis_image   = cell2struct({'Visual Image','fixed','',loadStim},...
                            {'description','fieldtype','value','callback'},2);
p.sync_c      = cell2struct({'Sync Channel','list',1,GetChannelList(wc.ai)},f_l,2);

p.stim_len      = cell2struct({'Stim Length','value', 300, 'ms'},f,2);
p.stim_delay    = cell2struct({'Stim Delay','value',200,'ms'},f,2);
p.stim_gain     = cell2struct({'Stim Gain','value',10,'(V)'},f,2);
p.frequency     = cell2struct({'Ep. Freq','value',0.2,'Hz'},f,2);
p.ep_length     = cell2struct({'Ep. Length','value',2000,'ms'},f,2);
p.stim_channel  = cell2struct({'Stimulator','list',1,GetChannelList(wc.ao)},f_l,2);
p.input_channel = cell2struct({'Input','list',1,GetChannelList(wc.ai)},f_l,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
display  = @updateDisplay;
% reset display
setupVisual;
% acq params
sr       = get(wc.ai, 'SampleRate');
length   = GetParam(me,'ep_length','value');
len      = length * sr / 1000;
set(wc.ai,'SamplesPerTrigger',len)
set(wc.ai,'SamplesAcquiredActionCount',len)
set(wc.ai,'SamplesAcquiredAction',{me, display}) 
set(wc.ai,'ManualTriggerHwOn','Start')
set(wc.ao,'SampleRate', 1000)
% hardware triggering via TTL to PFI0 and PFI6
set(wc.ai,'TriggerDelay',0)
set([wc.ai wc.ao], 'TriggerType','HwDigital')

function setupVisual()
% visual output: loads a .s0 file into video memory
stimfile = GetParam(me,'vis_image','value');
[s st]   = LoadStimulusFile(stimfile);
if isempty(s)
    error(st)
end
% cgcoltab(0,s.colmap);
% cgnewpal;
cgloadarray(1,s.xres,s.yres,s.stim,s.colmap);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function queueStimulus()
% populates the wc.ao data channels.  We can only output data after
% the flash trigger has gone off, so the length of the output data is
% episode length - visual delay, and delay times must be offset by the
% visual delay.
global wc

len         = GetParam(me,'ep_length','value');                 %ms
%trig_delay  = GetParam(me,'vis_delay','value');                 %ms
dt          = 1000 / get(wc.ao,'SampleRate');                   %ms/sample
%len         = len - trig_delay;
p           = zeros(len / dt, length(wc.ao.Channel));
% stimulator
ch          = GetParam(me,'stim_channel','value');
del         = GetParam(me,'stim_delay','value') / dt; %samples
i           = del+1:(del+ GetParam(me,'stim_len','value'));
p(i,ch)     = GetParam(me,'stim_gain','value');
% injection
ch          = GetParam(me,'inj_channel','value'); 
del         = GetParam(me,'inj_delay','value') / dt; %samples
dur         = GetParam(me,'inj_length','value') / dt;               %samples
gain        = GetParam(me,'inj_gain','value');
i           = del+1:del+dur;
p(i,ch)     = gain;
putdata(wc.ao,p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn  = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
queueStimulus;
start([wc.ai wc.ao]);
imageOn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function loadStimulus(varargin)
mod         = varargin{3};
param       = varargin{4};
s           = varargin{5};
t           = [mod '.' param];
h           = findobj(gcbf,'tag',t);
v           = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2]   = uigetfile([pn filesep '*.s0']);
if ~isnumeric(fn2)
    v       = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s       = SetParam(mod, param, v);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imageOn()
% handles display of triggering rectangle and stimulus
% gets called for each episode. waits delay and flips
% display for duration (which is what triggers acquisition)
del = GetParam(me,'vis_delay','value'); % ms
dur = GetParam(me,'vis_len','value') / 1000;
[x y pw ph] = CGDisplay_Position;
% displays sync rectangle & pause
cgrect(-320,-240,100,100,[1,1,1])
cgflip(0,0,0)       
pause(del/1000)
% display frame
cgdrawsprite(1, x, y, pw, ph)
cgrect(-320,-240,100,100,[0,0,0])
cgflip(0,0,0)
% remove stimulus
pause(dur)
cgrect(-320,-240,100,100,[1,1,1])
cgflip(0,0,0)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function updateDisplay(obj, event)
% clear the stimulus display
cgflip(0,0,0)
% plots and analyzes the data
[data, time, abstime] = getdata(obj);
plotData(data, time, abstime);
t                     = 1 / GetParam(me,'frequency','value');
t2                    = GetParam(me,'ep_length','value') / 1000;
pause(t - t2)
a                     = get(obj,'SamplesAcquiredAction');
if ~isempty(a)
    startSweep;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotData(data, time, abstime)
% plots the data

index       = GetParam(me,'input_channel','value');
data        = data(:,index);
axes(getScope)
% plot the data and average response
a               = get(gca, 'UserData'); % avgdata is now a cell array
if isempty(a)
    numtraces   = 1;
    avgdata     = data;
else
    avgdata     = a{2};
    numtraces   = a{1} + 1;
    avgdata     = avgdata + (data - avgdata) / (numtraces);
end
plot(time * 1000, [data avgdata])
a               = {numtraces, avgdata};
set(gca,'UserData', a);
EpisodeStats('plot', abstime, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function [] = clearScope()
axes(getScope)
set(gca,'UserData',[])
cla

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
