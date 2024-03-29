function varargout = SealTest(varargin)
%
% The SealTest module is one of the first I wrote; thus, it lacks many of the
% conventions that were instituted later.  However, it performs its function
% well enough, so there is little point in refactoring it just to make it look
% pretty.  Its job is to determine the resistance of the pipette by sending command
% voltage pulses to the amplifier and measuring the amount of current that passes
% through the tip.  Like a standard wholecell protocol, it has an 'init' action, but
% once the module is initialized, it has its own buttons for starting and stopping
% acquisition.  It also supports a 'standalone' mode, which is primarily used for
% debugging.
%
% See Also:
%    SealTest.fig
%
% $Id$

global wc

error(nargchk(1,Inf,nargin));
if isobject(varargin{1})
    feval(varargin{3},varargin{1:2});
    return;
end
action = lower(varargin{1});
switch lower(action)
    
case 'standalone'

    initializeHardware(me);
    SealTest('init');
    
case 'init'
    OpenGuideFigure(me);

    wc.sealtest.pulse         = 5;
    wc.sealtest.pulse_length  = 0.04;
    wc.sealtest.n_sweeps      = 3;
    wc.sealtest.scaling       = [1 0 0 0];  % the default is auto

    SetUIParam(me,'axes','NextPlot','ReplaceChildren');
    lbl = get(wc.sealtest.handles.axes,'XLabel');
    set(lbl,'String','Time (ms)');
    lbl = get(wc.sealtest.handles.axes,'YLabel');
    set(lbl,'String',['Current (' get(wc.ai.Channel(1),'Units') ')']);
    
    SetUIParam(me,'pulse','String',num2str(wc.sealtest.pulse))
    SetUIParam(me,'commandUnits','String',get(wc.ao.Channel(1),'Units'));
    SetUIParam(me,'sweeps','String',num2str(wc.sealtest.n_sweeps));
    SetUIParam(me,'pulseLengthUnits','String','ms');
    SetUIParam(me,'pulse_length','String',num2str(1000 .* wc.sealtest.pulse_length));
    SetUIParam(me,'scaling_0','Value',1);
    
% these callbacks are associated with buttons in the GUI.  See SealTest.fig to change
case 'sweeps_callback'
    try
        n_sweeps = str2num(get(wc.sealtest.handles.sweeps,'String'));
        wc.sealtest.n_sweeps = n_sweeps;
    catch
        SetUIParam(me,'sweeps','String',num2str(wc.sealtest.n_sweeps));
    end
    
case 'pulse_length_callback'
    try
        pulse_length = str2num(GetUIParam(me, 'pulse_length','String'));
        wc.sealtest.pulse_length = pulse_length / 1000;
    catch
        SetUIParam(me,'pulse_length','String',num2str(wc.sealtest.pulse_length));
    end
    run(me,'reset');
        
case 'pulse_callback'
    try
        pulse = str2num(GetUIParam(me,'pulse','String'));
        wc.sealtest.pusle =  pulse;
    catch
        SetUIParam(me, 'pulse','String',num2str(wc.sealtest.pulse));
    end
    run(me,'reset');
    
case 'scaling_callback'
    setScaling(me);
    
case 'close_callback'
    ClearAI(wc.ai);
    ClearAO(wc.ao);
    DeleteFigure(me);
    
case 'run_callback'
    run(me,'switch');
    
otherwise
    disp([action ' is not supported yet.']);
    
end

% local functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function run(fcn,action)
global wc
    state = GetUIParam(me,'runbutton','Value');
    if (state > 0)
        SetUIParam(me,'runbutton','String','Running');
        setupSweep(me);
        wc.sealtest.resist = [];
        StartAcquisition(me,[wc.ai wc.ao]);
    else
        SetUIParam(me,'runbutton','String','Stopped');
        stop([wc.ai wc.ao]);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function setScaling(fcn)
global wc
% there has GOT to be a better way to handle this
h        = wc.sealtest.handles;
buttons  = [h.scaling_0 h.scaling_1 h.scaling_2 h.scaling_3];
v        = get(buttons,'Value');
values   = [v{1} v{2} v{3} v{4}];
switched = values - wc.sealtest.scaling;
set(buttons(find(switched > 0)),'Value',1);
set(buttons(find(switched < 1)),'Value',0);
v        = get(buttons,'Value');
wc.sealtest.scaling = [v{1} v{2} v{3} v{4}];
switch num2str(find(wc.sealtest.scaling))
    case '1'
        SetUIParam(me,'axes',{'YLimMode'},{'auto'});
    case '2'
        SetUIParam(me,'axes','YLim',[-5 5]);
    case '3'
        SetUIParam(me,'axes','YLim',[-1 5]);
    case '4'
        SetUIParam(me,'axes','YLim',[-1 1]);
    otherwise
        SetUIParam(me,'axes',{'YLimMode','XLimMode'},{'manual','manual'});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function initializeHardware(fcn)
% This function initializes the WC structure and the DAQ when the
% module is called in standalone mode.
global wc

InitWC;
InitDAQ(5000);

wc.control.amplifier      = CreateChannel(wc.ai, 0, {'ChannelName','Units'}, {'Im','nA'});
wc.control.telegraph.gain = 2;
CreateChannel(wc.ai, wc.control.telegraph.gain);
wc.control.command        = CreateChannel(wc.ao, 0,...
    {'ChannelName','Units','UnitsRange'},{'Vcommand', 'mV', [-200 200]}); % 20 mV/V

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupSweep(fcn)
% each sweep is twice as long as the pulse.  we have to convert between
% samples and time rather too often.
global wc
acq     = @analyze;
[start, finish, sweeplen]        = pulseTimes;
numouts          = length(wc.ao.Channel);
wc.control.pulse = zeros(sweeplen,numouts);
wc.control.pulse(start:finish,1) = wc.sealtest.pulse;  % here we assume the first channel is the command
set(wc.ai,'SamplesPerTrigger',inf);
set(wc.ai,'SamplesAcquiredAction',{me, acq})
set(wc.ai,'SamplesAcquiredActionCount',length(wc.control.pulse));
sr               = get(wc.ai,'SampleRate');
set(wc.ao,'SampleRate',sr);
set(wc.ai,'UserData',length(wc.control.pulse));
set([wc.ai wc.ao],'StopAction','daqaction')
set([wc.ai wc.ao],'TriggerType','Manual')
set(wc.ai,'ManualTriggerHwOn','Trigger')
putdata(wc.ao, wc.control.pulse);
set(wc.ao,'RepeatOutput',inf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [start, finish, total] = pulseTimes;
global wc
len     = fix(wc.sealtest.pulse_length .* wc.control.SampleRate);
total   = 2 .* len;
start   = fix(.5 .* len);
finish  = start + len;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = analyze(obj, event)
% This function gets called as a result of the SamplesAcquiredAction.  It
% retrieves the data from the DAQ engine and passes it to plotData()
samples         = get(obj,'UserData');
[data, time]    = getdata(obj, samples);
plotData(time,data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = plotData(time, data)
% plots data on the graph and displays resistance values
% no averaging occurs on sweep display, but the user can set how many sweeps
% to use for resistance averaging
global wc

channel = wc.control.amplifier.Index;
data    = data(:,channel);
time    = (time(:) - time(1)) .* 1000;
plot(time, data, 'Parent', wc.sealtest.handles.axes);

[Rt, Rs, Ri]       = calculateResistance(data, wc.sealtest.pulse);
wc.sealtest.resist = cat(1,wc.sealtest.resist,[Rt Rs Ri]);
if size(wc.sealtest.resist,1) >= wc.sealtest.n_sweeps
    r = mean(wc.sealtest.resist,1);
    wc.sealtest.resist = [];
    SetUIParam(me,'ri','String',sprintf('%4.2f',r(3)));
    SetUIParam(me,'rs','String',sprintf('%4.2f',r(2)));
    SetUIParam(me,'rt','String',sprintf('%4.2f',r(1)));
    SetUIParam(me,'gain','String',num2str(get(wc.control.amplifier,'UnitsRange')));
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function [Rt, Rs, Ri] = calculateResistance(data, Vpulse)
% calculates the input and series resistance from the first column of data
% the transient should occur at the maximum.
% units are in mV/pA = MOhm.
% This function is annoying b/c dividing is really prone to error propagation,\
% and the noise can often overwhelm the transient, leading to mis-estimation of
% a lot of different things.
d           = data(:,1);
len         = length(data);
[y, start]  = max(d);
[y, finish] = min(d);
if (start < 21 | start > finish | finish > (len-11))
    [start, finish] = pulseTimes;
end
baseline    = mean(d(10:start-10));
It          = (d(start) - baseline);
Is          = (d(start+10) - baseline);
Ii          = (d(finish-20) - baseline);
[Rt, Rs, Ri] = deal(Inf);
if (It ~= 0)
    Rt = Vpulse./It;
end
if (Is ~= 0)
    Rs = Vpulse./Is;
end
if (Ii ~= 0)
    Ri = Vpulse./Ii;
end