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
    
case 'init'
    wc = '';
    wc.sealtest.pulse = 5; % 20 mV
    wc.sealtest.pulse_length = .040;  % s
    wc.sealtest.n_sweeps = 3;
    wc.sealtest.samplerate = 5000;
    wc.sealtest.scaling = [1 0 0 0];  % auto

    initializeHardware(me); % this gets replaced with information from central app
    
    fig = openfig(mfilename,'reuse');
    clfcn = sprintf('%s(''close_Callback'');',me);
    set(fig,'numbertitle','off','name',me,'tag',me,...
        'DoubleBuffer','on','menubar','none','closerequestfcn',clfcn);
    wc.sealtest.handles = guihandles(fig);
    guidata(fig, wc.sealtest.handles);

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
    daqreset;
    [obj, figure] = gcbo;
    delete(figure);
    
case 'run_callback'
    run(me,'switch');
    
otherwise
    disp([action ' is not supported yet.']);
    
end

% local functions

function out = me()
out = mfilename;

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

function initializeHardware(fcn)
global wc
daqreset
wc.ai = analoginput('nidaq');
set(wc.ai,'InputType','SingleEnded');
wc.ao = analogoutput('nidaq');
in = addchannel(wc.ai,[0],{'Im'});
set(in, 'Units', 'nA');
out = addchannel(wc.ao, 0, 'Vcommand');
set(out, 'Units', 'mV');
set(out, 'UnitsRange', [-200 200]); % 20 mV/V

set([wc.ai wc.ao], 'SampleRate', wc.sealtest.samplerate);
wc.sealtest.samplerate = get(wc.ai, 'SampleRate');
set([wc.ai wc.ao], 'TriggerType', 'Manual');
set(wc.ai, 'ManualTriggerHwOn', 'Trigger');

function setupSweep(fcn)
% each sweep is twice as long as the pulse.  we have to convert between
% samples and time rather too often.
global wc
sweeplen = fix(2 .* wc.sealtest.pulse_length .* wc.sealtest.samplerate);
start = fix(.3 .* wc.sealtest.pulse_length .* wc.sealtest.samplerate);
finish = start + (wc.sealtest.pulse_length .* wc.sealtest.samplerate);
wc.command = zeros(sweeplen,1);
wc.command(start:finish,:) = wc.sealtest.pulse;
set(wc.ai,'SamplesPerTrigger',inf);
set(wc.ao,'SamplesOutputAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data
set(wc.ao,'SamplesOutputActionCount',length(wc.command))
set([wc.ai wc.ao],'StopAction','daqaction')
putdata(wc.ao, wc.command);
set(wc.ao,'RepeatOutput',inf);

function plotData(time, data)
global wc

if (~isfield(wc.sealtest,'sweeps'))
    wc.sealtest.sweeps = data;
elseif (size(wc.sealtest.sweeps,3) <= wc.sealtest.n_sweeps)
    wc.sealtest.sweeps = cat(3,wc.sealtest.sweeps,data);
else
    data = mean(wc.sealtest.sweeps,3);
    wc.sealtest.sweeps = data;
    time = (time(:) - time(1)) .* 1000;
    [Rt, Rs, Ri] = calculateResistance(data, wc.sealtest.pulse);
    set(wc.sealtest.handles.ri,'String',num2str(Ri));
    set(wc.sealtest.handles.rs,'String',num2str(Rs));
    set(wc.sealtest.handles.rt,'String',num2str(Rt));
    %[Xdim, Ydim] = get(wc.sealtest.handles.axes,{'XLim', 'YLim'});
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
    

function [Rt, Rs, Ri] = calculateResistance(data, Vpulse)
% calculates the input and series resistance from the first column of data
% the transient will occur at the maximum
% units are in mV/pA = MOhm
d = data(:,1);
[y, i] = max(d);
baseline = mean(d(10:i-10));
Rt = Vpulse/(d(i) - baseline);
Rs = Vpulse/(d(i+10) - baseline);
[y, i] = min(d);
Ri = Vpulse/(d(i-20) - baseline);