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

    wc.sealtest.pulse = 5; % 20 mV
    wc.sealtest.pulse_length = .040;  % s
    wc.sealtest.n_sweeps = 3;
    wc.sealtest.scaling = [1 0 0 0];  % auto

    set(wc.sealtest.handles.axes,'NextPlot','ReplaceChildren');
    lbl = get(wc.sealtest.handles.axes,'XLabel');
    set(lbl,'String','Time (ms)');
    lbl = get(wc.sealtest.handles.axes,'YLabel');
    set(lbl,'String',['Current (' get(wc.ai.Channel(1),'Units') ')']);
    
    set(wc.sealtest.handles.pulse,'String',num2str(wc.sealtest.pulse))
    set(wc.sealtest.handles.commandUnits,'String',get(wc.ao.Channel(1),'Units'));
    set(wc.sealtest.handles.sweeps,'String',num2str(wc.sealtest.n_sweeps));
    set(wc.sealtest.handles.pulseLengthUnits,'String','ms');
    set(wc.sealtest.handles.pulse_length,'String',num2str(1000 .* wc.sealtest.pulse_length));
    set(wc.sealtest.handles.scaling_0,'Value',1);
    
case 'sweep' % plot the data
    data = varargin{2};
    time = varargin{3};
    plotData(time, data);
    
case 'sweeps_callback'
    try
        n_sweeps = str2num(get(wc.sealtest.handles.sweeps,'String'));
        wc.sealtest.n_sweeps = n_sweeps;
    catch
        set(wc.sealtest.handles.sweeps,'String',num2str(wc.sealtest.n_sweeps));
    end
    
case 'pulse_length_callback'
    try
        pulse_length = str2num(get(wc.sealtest.handles.pulse_length,'String'));
        wc.sealtest.pulse_length = pulse_length / 1000;
    catch
        set(wc.sealtest.handles.pulse_length,'String',num2str(wc.sealtest.pulse_length));
    end
    run(me,'reset');
        
case 'pulse_callback'
    try
        pulse = str2num(get(wc.sealtest.handles.pulse,'String'));
        wc.sealtest.pulse = pulse;
    catch
        set(wc.sealtest.handles.pulse,'String',num2str(wc.sealtest.pulse));
    end
    run(me,'reset');
    
case 'scaling_callback'
    setScaling(me);
    
case 'close_callback'
    stop([wc.ai wc.ao]);
    delete(gcbf);
    
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
    state = get(wc.sealtest.handles.runButton,'Value');
    if (state > 0)
        set(wc.sealtest.handles.runButton,'String','Running');
        switch action
        case 'reset'
            stop([wc.ai wc.ao]);
        otherwise
        end
        setupSweep(me);
        wc.sealtest.sweeps = [];
        start([wc.ai wc.ao]);
        trigger([wc.ai wc.ao]);
    else
        set(wc.sealtest.handles.runButton,'String','Stopped');
        stop([wc.ai wc.ao]);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function initializeHardware(fcn)
global wc

InitWC;
InitDAQ(5000);

wc.control.amplifier = CreateChannel(wc.ai, 0, {'ChannelName','Units'}, {'Im','nA'});
wc.control.telegraph.gain = 2;
CreateChannel(wc.ai, wc.control.telegraph.gain);
out = CreateChannel(wc.ao, 0, {'ChannelName','Units','UnitsRange'},{'Vcommand', 'mV', [-200 200]}); % 20 mV/V

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupSweep(fcn)
% each sweep is twice as long as the pulse.  we have to convert between
% samples and time rather too often.
global wc
[start, finish, sweeplen] = pulseTimes;
wc.command = zeros(sweeplen,1);
wc.command(start:finish,:) = wc.sealtest.pulse;
set(wc.ai,'SamplesPerTrigger',inf);
set(wc.ao,'SamplesOutputAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data
set(wc.ao,'SamplesOutputActionCount',length(wc.command)+20)  % some padding
set([wc.ai wc.ao],'StopAction','daqaction')
putdata(wc.ao, wc.command);
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
global wc

channel = wc.control.amplifier.Index;
% enable this to drop unnecessary channels
data = data(:,channel);
if (~isfield(wc.sealtest,'sweeps'))
    wc.sealtest.sweeps = data;
elseif (size(wc.sealtest.sweeps,3) <= wc.sealtest.n_sweeps)
    wc.sealtest.sweeps = cat(3,wc.sealtest.sweeps,data);
else
    data = mean(wc.sealtest.sweeps,3);
    wc.sealtest.sweeps = data;
    time = (time(:) - time(1)) .* 1000;
    [Rt, Rs, Ri] = calculateResistance(data, wc.sealtest.pulse);
    set(wc.sealtest.handles.ri,'String',sprintf('%4.2f',Ri));
    set(wc.sealtest.handles.rs,'String',sprintf('%4.2f',Rs));
    set(wc.sealtest.handles.rt,'String',sprintf('%4.2f',Rt));
    set(wc.sealtest.handles.gain,'String',num2str(get(wc.control.amplifier,'UnitsRange')));
%    disp(sprintf('%i - %i',length(time),length(data)));
    plot(time, data, 'Parent', wc.sealtest.handles.axes);
    switch num2str(find(wc.sealtest.scaling))
    case '1'
        set(wc.sealtest.handles.axes,'DataAspectRatioMode','auto');
        set(wc.sealtest.handles.axes,'YLimMode','auto');
    case '2'
        set(wc.sealtest.handles.axes,'YLim',[-5 5]);
    case '3'
        set(wc.sealtest.handles.axes,'YLim',[-1 5]);
    case '4'
        set(wc.sealtest.handles.axes,'YLim',[-1 1]);
    otherwise
        set(wc.sealtest.handles.axes,'YLimMode','manual');
    end
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
    

