function varargout = Episode(varargin)
%
% This basic protocol acquires episodes from the amplifier and
% records the response to stimulation.  It uses the internal clock
% to trigger, which may be a bugaboo if we want to record but
% only stimulate at 0.2 Hz.
%
% void Episode(action, control)
%
% action is ('init') 'play', 'record', or 'stop'
% control is a structure that defines parameters for the experiment
%
% control.length - time, in seconds for each episode
% control.frequency - frequency, in Hz, of episode acquisition
% control.stim_delay - time, in seconds, to wait to trigger the stimulator
%
% $Id$

global wc

if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action

case {'init','reinit'}
    fig = OpenGuideFigure(me);
    SetUIParam(me,'input_channel','String',GetChannelList(wc.ai));
    cs = GetChannelList(wc.ao);
    SetUIParam(me,'stim_channel','String',cs);
    SetUIParam(me,'command_channel','String',cs);
    
    if (isfield(wc.control,'episode'))
        setValues(wc.control.episode);
    else
        setValues; % sets default values based on whole-cell attributes
    end
    
case 'start'
    control = getValues;
    setupHardware(control);
    setupScope(wc.wholecell.handles.scope, wc.control.amplifier, control);
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    SetUIParam('wholecell','progress_txt','String','Sweeps Acquired:');
    SetUIParam('wholecell','progress','String','0');
    startSweep;
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        Episode('stop');
    end
    control = getValues;
    setupHardware(control);
    setupScope(wc.wholecell.handles.scope, wc.control.amplifier, control);
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    SetUIParam('wholecell','progress_txt','String','Sweeps Acquired:');
    SetUIParam('wholecell','progress','String','0');
    % data is stored in a directory, one file per sweep.
    wc.episode.lastlogfilename = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(wc.episode.lastlogfilename);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Index'});
    startSweep;
    
    
case 'stop'
    set(wc.ao,'StopAction','');
    stop([wc.ai wc.ao]);
    set(wc.ai,'LoggingMode','Memory');
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    % set the next file name up correctly
    if (isfield(wc.episode, 'lastlogfilename'))
        set(wc.ai,'LogFileName',NextDataFile(wc.episode.lastlogfilename));
    end

case 'sweep'
    data = varargin{2};
    time = varargin{3};
    plotData(data, time, wc.wholecell.handles.scope, wc.control.amplifier.Index);
    sw = str2num(GetUIParam('wholecell','progress','String'));
    SetUIParam('wholecell','progress','String',num2str(sw+1));
    
case 'newsweep'
    startSweep;

% callbacks
case 'value_changed_callback' % called whenever a field is edited
    wc.control.episode = getValues;
    
case 'load_command_callback'
    [fn pn] = uigetfile('*.mat','Load command pulse');
    c = load([pn fn]);
    if (isfield(c,'command'))
        SetUIParam(me,'command_gain','UserData',c.command);
        Episode('value_changed_callback');
    end
    
case 'view_command_callback'
    a = axes;
    d = GetUIParam(me,'command_gain','UserData');
    if ~isempty(d)
        plot(d,'Parent',a);
    end

case 'load_protocol_callback'
    [fn pn] = uigetfile('*.mat','Load episode control data...');
    c = load([pn fn]);
    if (isfield(c,'control'))
        wc.control.episode = c.control;
        setValues(c.control);
    end
    
case 'save_protocol_callback'
    [fn pn] = uiputfile('*.mat','Save episode control data...');
    control = getValues;
    save([pn fn],'control');
    
case 'close_callback'
    delete(gcbf);
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setValues(varargin)
% sets values in the GUI to those in a control structure
% or if no arguments are given, to default values
global wc
if (nargin > 0)
    control = varargin{1};
    SetUIParam(me,'length','String',num2str(control.length));
    SetUIParam(me,'frequency','String',num2str(control.frequency));
    SetUIParam(me,'stim_delay','String',num2str(control.stim_delay));
    SetUIParam(me,'command_gain','String',num2str(control.command_gain));
    SetUIParam(me,'command_gain','UserData',control.command);
    SetUIParam(me,'command_delay','String',num2str(control.command_delay));
    if (control.input_channel <= length(GetUIParam(me,'input_channel','String')))
        SetUIParam(me,'input_channel','Value',control.input_channel);
    end
    if (control.stim_channel <= length(GetUIParam(me,'stim_channel','String')))
        SetUIParam(me,'stim_channel','Value',control.stim_channel);
    end
    if (control.command_channel <= length(GetUIParam(me,'command_channel','String')))
        SetUIParam(me,'command_channel','Value',control.command_channel);
    end
    
else
    SetUIParam(me,'length','String','1000');
    SetUIParam(me,'frequency','String','0.2');
    SetUIParam(me,'stim_delay','String','0');
    SetUIParam(me,'command_gain','String','1');
    SetUIParam(me,'command_delay','String','0');
    ic = get(wc.control.amplifier,'Index');
    if (ic <= length(GetUIParam(me,'input_channel','String')))
        SetUIParam(me,'input_channel','Value',ic);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function control = getValues()
% returns all the values from the gui
control.length = str2num(GetUIParam(me,'length','String'));
control.frequency = str2num(GetUIParam(me,'frequency','String'));
control.stim_delay = str2num(GetUIParam(me,'stim_delay','String'));
control.command_gain = str2num(GetUIParam(me,'command_gain','String'));
control.command = GetUIParam(me,'command_gain','UserData');
control.command_delay = str2num(GetUIParam(me,'command_delay','String'));
control.input_channel = GetUIParam(me,'input_channel','Value');
control.stim_channel = GetUIParam(me,'stim_channel','Value');
control.command_channel = GetUIParam(me,'command_channel','Value');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function varargout = startSweep()
% Begins a sweep
global wc;
stop([wc.ai wc.ao]);
% delay...
putdata(wc.ao, wc.control.pulse);
start([wc.ai wc.ao]);
trigger([wc.ai wc.ao]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupHardware(control)
% Sets up the hardware for this mode of acquisition
global wc

sr = get(wc.ao, 'SampleRate');
len = (control.length / 1000) * sr;
pulse_len = 0.3 * len;
set(wc.ai,'SamplesPerTrigger',len);
set(wc.ai,'SamplesAcquiredActionCount',len);
set(wc.ai,'SamplesAcquiredAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data
set(wc.ao,'StopAction',{'PausedCallback',me,(1/control.frequency - control.length/1000),'newsweep',}); % the daq's timer is used to initiate repeat sweeps

numouts = length(wc.ao.Channel);
wc.control.pulse = zeros(len,numouts);
p = control.stim_delay+1:control.stim_delay+pulse_len;
wc.control.pulse(p, control.stim_channel) = 10;
if (~isempty(control.command_gain) & length(control.command) >= len)
    wc.control.pulse(:,control.command_channel) = control.command(1:len) * control.command_gain;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupScope(scope, amp, control);
% sets up the scope properties
clearPlot(scope);
set(scope, 'YLim', [-3 3]);
%set(scope, 'YLimMode','manual','XLimMode','manual');
set(scope, 'NextPlot', 'replacechildren');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
lbl = get(scope,'YLabel');
set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(data, time, scope, index)
% plots the data

data = data(:,index);
plot(time * 1000, data, 'Parent', scope);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
kids = get(axes, 'Children');
delete(kids);