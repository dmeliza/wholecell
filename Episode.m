function varargout = Episode(varargin)
%
% The wholecell toolkit works through modules, which are mfiles that control
% experiments of a similar type.  This module, Episode.m, is probably the most
% basic protocol, and should be used as an example for writing other modules.  In an
% episode, the data acquisition hardware is instructed to acquire data for a brief
% perioid of time, during which a signal can also be sent through the analogoutput
% device.  After a pause, the episode is repeated.  Individual episodes can be
% treated separately, or as is more common, averaged together to minimize noise.  Also,
% there are usually several parameters that can be extracted from each episode (e.g.
% input resistance); this module provides online tracking of these parameters (still
% somewhat limited.)
%
% void Episode(action)
%
% Input:    The user can specify a pulse on one or both of the analog output channels.
%           The length, delay, and amplitude of the pulse can be specified, but only
%           one pulse per channel is permitted.
%
% Output:   The module generates the sequences that will cause the analogoutput to
%           output the pulses specified by the user.  It also instructs the DAQ toolkit
%           to acquire data at the default samplerate for the length of time specified
%           by the user.
%
% Details:  There are few issues with a protocol this simple.  The biggest one stems
%           from a bug of some kind in the driver or DAQ toolkit that can cause the ao
%           and ai objects to not start at the same time, which causes a significant
%           jitter in the timing of events within individual episodes.  As there does
%           not seem to be any truly reliable way of eliminating the problem that does
%           not also greatly complicate the code (for instance, one could use a Software
%           or Hardware trigger to start the ai object), a post-hoc method of correction
%           is supplied in the Analysis/AlignEpisodes() function.
%
%           Some flexibility is lost because only single pulses can be sent on each
%           channel.  In my view this is more than made up for by the ease with which
%           the episode parameters can be set and edited.  Writing a more flexible
%           episode specification tool/module is left as an exercise to the reader.
%
% Notes:    A protocol needs to respond to certain actions, which are passed as string
%           arguments by the calling function (usually ProtocolControl.m).  The minimum
%           set of arguments are 'init', 'start', 'record', and 'stop', which are called
%           when the user clicks the Init, Play, Record, or Stop buttons, respectively.
%
%           Aside from responding to these actions, the protocol can operate however it likes.
%           If the user is expected to change parameters, it may pay, however, to use
%           the ParamFigure function to create a figure that will present the relevant
%           parameters to the user.  This figure is created with callbacks that ensure that
%           the wc control structure is updated whenever the user changes something, so
%           that the GetParam function can be used to retrieve those parameters whether
%           or not the parameter window is still open.
%
%           The DAQ toolkit works using Actions, which are executed whenever an event
%           happens (for instance, the requested number of samples have been acquired).
%           IMPORTANT: this convention was used in the version 2.0 toolkit included with
%           Matlab R12; in subsequent versions the Actions are functions, with the important
%           difference that these can be function handles, whereas actions have to be
%           mfiles, specified by a string.  Thus, to call an internal function, this
%           module implements a workaround, where the Action is set to {mfilename, fcn},
%           and a call to isobject() in the main function is used to determine if the
%           action is a handle or a string.  Using internal functions means that code
%           tends to be duplicated between protocols, but also simplifies debugging.
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
    % The Init action is called by the Init button in ProtocolControl. It
    % initializes the parameter window and the scopes.
    p = defaultParams;
    fig = ParamFigure(me, p);
    getScope;
    
    EpisodeStats('init','min','','PSR_IR');
    
case 'start'
    % The start action is called by the Play button in ProtocolControl. It
    % sets up the driver parameters, queues data in the analog ouput, and
    % starts acquisition
    setupHardware;
    clearScope;
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    set(wc.ai,'LogFileName',fullfile(dir, '0000.daq'));
    EpisodeStats('clear');
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    
case 'record'
    % The record action is called by the Record button in ProtocolControl. It
    % acts like the start action, but sets the driver to record results on
    % disk as well as in memory.
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
    % The stop action is called by the Stop button in ProtocolControl. It stops
    % the protocol and clears important driver settings so that subsequent
    % acquisitions (which may be called by other protocols) don't generate recordings
    % or use the wrong callbacks
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
    % catches actions that have not had cases written for them, and
    % displays a helpful message (which can be commented out once
    % debugging is over (hah!))
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
% This function is here merely for convenience so that
% the value 'me' refers to the name of this mfile (which
% is used in accessing parameter values)
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = defaultParams;
% This function generates a structure that can be passed to
% ParamFigure.  The structure describes the parameters relevant
% to this protocol, their types, units, and default values.
% See Utility/ParamFigure.m for more information on how this structure
% works.  Cell2Struct() is used to construct the structure for
% brevity; any structure-generating algorhythm can be used as long
% as the fields are named correctly.
global wc;
f = {'description','fieldtype','value','units'};
f_s = {'description','fieldtype','value'};
f_l = {'description','fieldtype','value','choices'};

p.inj_length = cell2struct({'Inj Length','value',6,'ms'},f,2);
p.inj_delay = cell2struct({'Inj Delay','value',200,'ms'},f,2);
p.inj_gain = cell2struct({'Inj Gain','value',1},f_s,2);
p.inj_channel = cell2struct({'Command','list',1,GetChannelList(wc.ao)},f_l,2);
p.stim_len = cell2struct({'Stim Length','value', 300, 'ms'},f,2);
p.stim_delay = cell2struct({'Stim Delay','value',200,'ms'},f,2);
p.stim_gain = cell2struct({'Stim Gain','value',10,'(V)'},f,2);
p.frequency = cell2struct({'Ep. Freq','value',0.2,'Hz'},f,2);
p.ep_length = cell2struct({'Ep. Length','value',1000,'ms'},f,2);
p.stim_channel = cell2struct({'Stimulator','list',1,GetChannelList(wc.ao)},f_l,2);
p.input_channel = cell2struct({'Input','list',1,GetChannelList(wc.ai)},f_l,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% This function is responsible for setting important values on the
% ai and ao objects, primarily the number of samples to record before
% calling the analysis function (and which function to call). This function
% should be called before each experiment (ie when the user presses Play or Record)
global wc
display = @updateDisplay;

sr = get(wc.ai, 'SampleRate');
length = GetParam(me,'ep_length','value');
len = length * sr / 1000;
set(wc.ai,'SamplesPerTrigger',len)
set(wc.ai,'SamplesAcquiredActionCount',len)
set(wc.ai,'SamplesAcquiredAction',{me, display}) 
set(wc.ao,'SampleRate', 1000)
set([wc.ai wc.ao],'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Trigger');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function queueStimulus()
% This function is responsible for queuing data in the
% analog output.  Data is queued using putdata().  A signal
% for each channel must be supplied, and the ao system
% will play this sequence back at the samplerate when
% the device is triggered.
global wc

len = GetParam(me,'ep_length','value');
dt = 1000 / get(wc.ao,'SampleRate');
p = zeros(len, length(wc.ao.Channel));
% stimulator
ch = GetParam(me,'stim_channel','value');
del = GetParam(me,'stim_delay','value') / dt;
i = del+1:(del+ GetParam(me,'stim_len','value'));
p(i,ch) = GetParam(me,'stim_gain','value');
% injection
ch = GetParam(me,'inj_channel','value');
del = GetParam(me,'inj_delay','value') / dt;
dur = GetParam(me,'inj_length','value') / dt;
gain = GetParam(me,'inj_gain','value');
i = del+1:del+dur;
p(i,ch) = gain;
putdata(wc.ao,p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function updateDisplay(obj, event)
% This is the function that gets called when the analoginput
% has acquired the number of samples it was set to acquire.  It
% extracts the data from the engine, passes it to the plotData()
% function, and then pauses for the correct amount of time before it
% calls startSweep() to acquire the next episode.
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
% This function handles the display of data in the plot window
% and in the analysis window (controlled by EpisodeStats).  In this
% protocol, we plot the most recently acquired sweep, as well as the
% average of all the sweeps acquired during the current experiment.
% The second sweep is harder to plot than would be expected, because we have
% to make data available from previous episodes available to the
% interpreter when this function is called.  Stateful data can be stored in
% a lot of places, but in this case we choose to use the 'UserData' field
% of the plot axis.  The mean trace, along with the number of traces represented
% by the mean, are stored in this field, allowing us to calculate the new
% mean trace without storing every single trace.
index       = GetParam(me,'input_channel','value');
data        = data(:,index);            % only the amplifier channel is plotted
axes(getScope)                          % get the scope
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% This function initiates a sweep acquisition.  This involves several tasks,
% the most important of which is that the stimulus must be requeued into the
% analogoutput object each time we want to play it back.  The function also
% makes sure the logfile name is advanced to the next number (using
% NextDataFile()) so that if the user has chosen to save the data, it will not
% overwrite previous episodes (very important!).
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
queueStimulus;
start([wc.ai wc.ao]);
trigger([wc.ai wc.ao]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function [] = clearScope()
% Very basic function; clears the axes and removes any stored data
% from the UserData field (so that the running average will be reset)
axes(getScope)
set(gca,'UserData',[])
cla

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function a = getScope()
% This function retrieves the handle for the scope axes, and if
% the axes don't exist, creates them and sets them with the proper
% values.
f       = findfig([me '.scope']);
set(f,'position',[288 314 738 508],'name','scope','numbertitle','off');
a       = get(f,'Children');
if isempty(a)
    a   = axes;
    set(a,'NextPlot','ReplaceChildren')
    set(a,'XTickMode','Auto','XGrid','On','YGrid','On','YLim',[-5 5])
    xlabel('Time (s)')
    ylabel('amplifier (V)')
end