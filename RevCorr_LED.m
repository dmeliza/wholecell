function varargout = RevCorr_LED(varargin)
%
% This protocol uses a flashing LED to determine the temporal
% receptive field of a cell in current or voltage clamp.  The voltage to
% the LED is output (gaussian white noise) and the signal from the amplifier
% is recorded.  The LED signal is stored for reverse correlation analysis.
%
% Online analysis looks for the first moment of the temporal filter (TBI).
%
% void RevCorr_LED(action)
%
% action is {'init'} 'play', 'record', or 'stop'
% other actions are used as internal callbacks
%
% parameters:
% (output)
%     - s_max: maximum output voltage to LED
%     - s_res: number of distinct output voltages
%     - t_res: frame rate of LED
% (analysis)
%     - s_len: length of stimulus to consider for rev corr
%     - r_thresh: minimum response to be considered a response
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
    fig = OpenParamFigure(me, p);
    Scope('init');
    
case 'start'
    setupHardware;
    setupScope;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    SetUIParam('scope','status','String','Not recording');
    queueStimulus;
    StartAcquisition(me,[wc.ai wc.ao]);
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        feval(me,'stop');
    end
    setupHardware;
    setupScope;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    lf = NextDataFile;
    set(wc.ai,'LogFileName',lf);
    SetUIParam('scope','status','String',lf);
    queueStimulus;
    StartAcquisition(me,[wc.ai wc.ao]);
    
case 'stop'
    stop([wc.ai wc.ao]);
    if (isvalid(wc.ai))
        set(wc.ai,'SamplesAcquiredAction','');
        set(wc.ai,'TimerAction','');
        SetUIParam('wholecell','status','String',get(wc.ai,'Running'));        
        set(wc.ai,'LoggingMode','Memory');
    end


case 'sweep'
    data = varargin{2};
    time = varargin{3};
    abstime = varargin{4};
%     in = get(wc.ai,'SamplesAvailable');
%     out = get(wc.ao,'SamplesAvailable');
%     status = sprintf('in: %d / out: %d',in, out); 
%     SetUIParam('scope','status','String',status);
    queueStimulus;
    plotData(data, time, abstime, getScope, wc.control.amplifier.Index);
    
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
    p.output.description = 'LED channel';
    p.output.fieldtype = 'list';
    p.output.choices = GetChannelList(wc.ao);
    p.output.value = 1;
    p.s_max.description = 'Max LED Voltage';
    p.s_max.fieldtype = 'value';
    p.s_max.units = 'V';
    p.s_max.value = 3.6;
    p.s_min.description = 'Min LED Voltage';
    p.s_min.fieldtype = 'value';
    p.s_min.units = 'V';
    p.s_min.value = 2.0;
    p.s_res.description = 'Stim Res';
    p.s_res.fieldtype = 'value';
    p.s_res.value = 5;
    p.t_res.description = 'Frame Rate';
    p.t_res.fieldtype = 'value';
    p.t_res.units = 'ms';
    p.t_res.value = 100;
    
    p.d_rate = cell2struct({'Display Rate','value',10,'Hz'},f,2);
    p.a_int = cell2struct({'Analyze every:','value',30,'s'},f,2);
    p.input.description = 'Amplifier Channel';
    p.input.fieldtype = 'list';
    p.input.choices = GetChannelList(wc.ai);
    ic = get(wc.control.amplifier,'Index');
    p.input.value = ic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
display = @updateDisplay;
analyze = @analyze;
sr = get(wc.ai, 'SampleRate');
u_rate = GetParam(me,'d_rate','value');
a_int = sr * GetParam(me,'a_int','value');
update = fix(sr / u_rate); 
set(wc.ai,'SamplesPerTrigger',a_int);
set(wc.ai,'TimerPeriod',1 / u_rate);
set(wc.ai,'TimerAction',{me,display})
set(wc.ai,'SamplesAcquiredActionCount',a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'DataMissedAction',{me,'showerr'});
set(wc.ai,'UserData',update);

t_res = GetParam(me,'t_res','value');
sr = 1000 / t_res ;
set(wc.ao, 'SampleRate', sr);

Spool('stim','init');
Spool('resp','init');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wn = whitenoise(samples)
% generates quantized one-dimensional gaussian white noise
s_max = GetParam(me,'s_max','value');
s_min = GetParam(me,'s_min','value');
s_res = GetParam(me,'s_res','value');
wn = randn(samples,1);
wn = wn - min(wn);
wn = round(wn * s_res / max(wn)) * (s_max - s_min) / s_res + s_min;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function queueStimulus()
% queues data in the ao object and records it to a param in wc
global wc
t_res = GetParam(me,'t_res','value');
a_int = GetParam(me,'a_int','value');
update = a_int * 1000 / t_res * 1.2;
queued = get(wc.ao,'SamplesAvailable');
if (queued < 0.1 * update)
    control = GetParam(me,'output','value');
    c = zeros(update, length(wc.ao.Channel));
    wn =  whitenoise(update);
    c(:,control) = wn;
    putdata(wc.ao, c);
    Spool('stim', 'append', wn');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function updateDisplay(obj, event)
% this method displays data, using peekdata to acquire the latest
% bit of data
samp = get(obj,'TimerPeriod');
sr = get(obj,'SampleRate'); % samp/sec
d = peekdata(obj,samp*sr);
sr = 1000/sr; % ms/samp
t = 0:sr:(length(d)-1)*sr;
plotData(t,d);
%queueStimulus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% this method analyzes the data, using getdata to clear the latest
% data from the buffer
global wc
[data, time, abstime] = getdata(obj);
index = wc.control.amplifier.Index;
stim = Spool('stim','retrieve');
samplerate = get(obj,'SampleRate');
stimrate = GetParam(me,'t_res','value');
stimstart = get(wc.ao,'InitialTriggerTime');

bin = samplerate * stimrate / 1000;
d = bindata(data(:,index)', bin);
offset = fix((datenum(stimstart) - datenum(abstime)) * 1000 / stimrate); % positive numbers - late stim
if offset > 0
    d = d(offset:end);
elseif offset < 0
    stim = stim(-offset:end);
end
% c = xxxcorr(d, stim);
% figure,plot(c);
window = 1000 / stimrate;
c = xxxcorr(d, stim,-window:2);
figure,plot((-window:2)*stimrate, c);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function scope = getScope()
scope = GetUIHandle('scope','scope');
if (isempty(scope) | ~ishandle(scope))
    Scope('init');
    scope = GetUIHandle('scope','scope');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupScope(scope, amp);
% sets up the scope properties
scope = getScope;
clearPlot(scope);
%set(scope, 'YLim', [-3 3]);
set(scope, 'XLim', [0 1000]);
set(scope, 'NextPlot', 'add');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(time, data)
% updates the scope with the latest bit of data
global wc

mode = GetParam('control.telegraph', 'mode');
gain = GetParam('control.telegraph', 'gain');
scope = getScope;
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
index = wc.control.amplifier.Index;
data = AutoGain(data(:,index), gain, units);
Scope('scope',time, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
Scope('clear');

%%%%%%%%%%%%%%%%%%%%%55
function c = xxxcorr(stim, resp, window)
% plots a quick crosscorrelation of the stimulus and response
stim = stim - mean(stim);
resp = resp - mean(resp);
c = xcorr(resp, stim);
if nargin == 3
    o = length(c) / 2;
    c = c(o + window);
end

%%%%%%%%%%%%%%%%%%%%%%%%5
function showerr(obj, event)
keyboard;

