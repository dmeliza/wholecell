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
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    set(wc.ai,'LogFileName',fullfile(dir, '0000.daq'));    
    startSweep;
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        feval(me,'stop');
    end
    setupHardware;
    setupScope;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));    
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    startSweep;
    
case 'stop'
    stop([wc.ai wc.ao]);
    if (isvalid(wc.ai))
        set(wc.ai,'SamplesAcquiredAction','');
        set(wc.ai,'TimerAction','');
        SetUIParam('wholecell','status','String',get(wc.ai,'Running'));        
        set(wc.ai,'LoggingMode','Memory');
        set(wc.ai,'LogFileName',NextDataFile);
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
trigger([wc.ai wc.ao]);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
display = @updateDisplay;
analyze = @analyze;
stop = @stopAO;
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
set(wc.ao,'StopAction',{me,stop});
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
    m = lower(get(wc.ai,'LoggingMode'));
    if ~strcmp('memory',m)
        lf = get(wc.ai,'Logfilename');
        writeStimulus(lf, wn, 1000 / t_res, a_int);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeStimulus(filename, stimulus, stimrate, analysis_interval)
% writes stimulus waveform to a mat file for later analysis
[pn fn ext] = fileparts(filename);
save([pn filesep fn '.mat'],...
    'stimulus', 'stimrate', 'analysis_interval');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function updateDisplay(obj, event)
% this method displays data, using peekdata to acquire the latest
% bit of data
samp = get(obj,'TimerPeriod');
sr = get(obj,'SampleRate'); % samp/sec
d = peekdata(obj,samp*sr);
if length(d) == samp*sr % short stuff is discarded
    sr = 1000/sr; % ms/samp
    t = 0:sr:(length(d)-1)*sr;
    plotData(t,d);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% this method analyzes the data, using getdata to clear the latest
% data from the buffer
global wc
window = [-1000 200];
[data, time, abstime] = getdata(obj);
index = wc.control.amplifier.Index;
stim = Spool('stim','retrieve');
samplerate = get(obj,'SampleRate');
t_res = GetParam(me,'t_res','value');
stimstart = get(wc.ao,'InitialTriggerTime');
c = revcorr(data(:,index)', stim, samplerate,...
    1000 / t_res, stimstart, abstime, window);
s = [me '.analysis'];
f = findobj('tag', s);
if isempty(f) | ~ishandle(f)
    f = figure('tag', s, 'numbertitle', 'off', 'name', s);
end
t = window(1):t_res:window(2);
figure(f);
d = get(f,'UserData');
d = cat(1,d,c);
a = mean(d,1);
p = plot(t, [c; a]);
xlabel('Time (ms)');
set(f,'name',[s ' - ' num2str(size(d,1)) ' scans']);
set(f,'UserData',d);
Spool('stim','delete');

startSweep;

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

%%%%%%%%%%%%%%%%%%%%%%%%5
function showerr(obj, event)
keyboard;

%%%%%%%%%%%%%%%%%%%%%%%%%
function stopAO(obj, event)
% clears the state of the analog output object
set(obj,'StopAction',{});
c = get(obj,'Channel');
putdata(obj,zeros(length(c)));
start(obj);
trigger(obj);