function varargout = SealTest(varargin)
% Seal test protocol: sends pulses through the amplifier
% command and determines the resistance of the electrode.
% void SealTest(action,[params])
% action can be 'init' or 'sweep' (presently)
% $Id$

global wc


if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action
    
case 'standalone'

    initializeHardware(me);
    SealTest('init');
    
case 'init'
    OpenGuideFigure(me);

%     InitParam(me,'pulse',5); % 5 mV
%     InitParam(me,'pulse_length', .040);  % s
%     InitParam(me,'n_sweeps',3);
    wc.sealtest.pulse = 5;
    wc.sealtest.pulse_length = 0.40;
    wc.sealtest.n_sweeps = 3;
    wc.sealtest.scaling = [1 0 0 0];  % auto

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
    
case 'sweep' % plot the data
    data = varargin{2};
    time = varargin{3};
    plotData(time, data);
    
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
    StopAcquisition(me, [wc.ai wc.ao]);
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
    state = GetUIParam(me,'runButton','Value');
    if (state > 0)
        SetUIParam(me,'runButton','String','Running');
        setupSweep(me);
        wc.sealtest.resist = [];
        StartAcquisition(me,[wc.ai wc.ao]);
    else
        SetUIParam(me,'runButton','String','Stopped');
        StopAcquisition(me,[wc.ai wc.ao]);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function setScaling(fcn)
global wc
% there has GOT to be a better way to handle this
h = wc.sealtest.handles;
buttons = [h.scaling_0 h.scaling_1 h.scaling_2 h.scaling_3];
v = get(buttons,'Value');
values = [v{1} v{2} v{3} v{4}];
switched = values - wc.sealtest.scaling;
set(buttons(find(switched > 0)),'Value',1);
set(buttons(find(switched < 1)),'Value',0);
v = get(buttons,'Value');
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
global wc

InitWC;
InitDAQ(5000);

sr = get(wc.ai,'SampleRate');
set(wc.ao,'SampleRate',sr);ret
wc.control.amplifier = CreateChannel(wc.ai, 0, {'ChannelName','Units'}, {'Im','nA'});
wc.control.telegraph.gain = 2;
CreateChannel(wc.ai, wc.control.telegraph.gain);
wc.control.command = CreateChannel(wc.ao, 0,...
    {'ChannelName','Units','UnitsRange'},{'Vcommand', 'mV', [-200 200]}); % 20 mV/V

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupSweep(fcn)
% each sweep is twice as long as the pulse.  we have to convert between
% samples and time rather too often.
global wc
[start, finish, sweeplen] = pulseTimes;
numouts = length(wc.ao.Channel);
wc.control.pulse = zeros(sweeplen,numouts);
wc.control.pulse(start:finish,1) = wc.sealtest.pulse;  % here we assume the first channel is the command
set(wc.ai,'SamplesPerTrigger',inf);
set(wc.ai,'SamplesAcquiredAction',{'SweepAcquired',me});
set(wc.ai,'SamplesAcquiredActionCount',length(wc.control.pulse)); 
set([wc.ai wc.ao],'StopAction','daqaction')
putdata(wc.ao, wc.control.pulse);
set(wc.ao,'RepeatOutput',inf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [start, finish, total] = pulseTimes;
global wc
len = fix(wc.sealtest.pulse_length .* wc.control.SampleRate);
total = 2 .* len;
start = fix(.3 .* len);
finish = start + len;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotData(time, data)
% plots data on the graph and displays resistance values
% no averaging occurs on sweep display, but the user can set how many sweeps
% to use for resistance averaging
global wc

channel = wc.control.amplifier.Index;
data = data(:,channel);
time = (time(:) - time(1)) .* 1000;
plot(time, data, 'Parent', wc.sealtest.handles.axes);

[Rt, Rs, Ri] = calculateResistance(data, wc.sealtest.pulse);
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
% the transient will occur at the maximum
% units are in mV/pA = MOhm.
% This function is annoying b/c dividing is really prone to errors.
d = data(:,1);
len = length(data);
[y, start] = max(d);
[y, finish] = min(d);
if (start < 21 | start > finish | finish > (len-11))
    [start, finish] = pulseTimes;
end
baseline = mean(d(10:start-10));
It = (d(start) - baseline);
Is = (d(start+10) - baseline);
Ii = (d(finish-20) - baseline);
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