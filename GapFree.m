function varargout = GapFree(varargin)
%
% GapFree is another simple protocol.  Its function is to record an
% uninterrupted sequence of samples from the analoginput (for instance,
% when recording the response of a cell to depolarization to ascertain its
% spike physiology).  From time to time this module will acquire data from
% the DAQ and plot it on a scope window.
%
%
% See Also:
%   Utility/Scope.m (.fig) - the auxiliary function that provides the method
%                            of oscilloscope-like plotting of the data
%
% $Id$
global wc

error(nargchk(1,Inf,nargin));

if isobject(varargin{1})
    feval(varargin{3},varargin{1:2});
    return;
end
action = lower(varargin{1});


switch action
case {'init','reinit'}
    Scope('init');              % initialize the plot window
    
case 'start'
    scope = getScope;
    setupScope(scope, wc.control.amplifier);
    setupHardware(wc.control.amplifier);
    SetUIParam('protocolcontrol','status','String','Playback');
    StartAcquisition(me,wc.ai);
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        stop(wc.ai);
    end
    scope = getScope;
    setupScope(scope, wc.control.amplifier);
    setupHardware(wc.control.amplifier);
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    lf = NextDataFile;
    set(wc.ai,'LogFileName',lf);
    SetUIParam('protocolcontrol','status','String',lf);
    StartAcquisition(me,wc.ai);
    
case 'stop'
    ClearAI(wc.ai);
    SetUIParam('protocolcontrol','status','String','Stopped');
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scope = getScope()
% returns the scope object or opens it if it doesn't exist
scope = GetUIHandle('scope','scope');
if (isempty(scope) | ~ishandle(scope))
    Scope('init');
    scope = GetUIHandle('scope','scope');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = setupHardware(amp)
% Sets up the hardware for this mode of acquisition
global wc
acq     = @analyze;
daq     = amp.Parent;
sr      = get(daq, 'SampleRate');
update  = fix(sr / 10); % update at 20 Hz
set(daq,'SamplesPerTrigger',inf);
set(daq,'SamplesAcquiredAction',{me, acq}) % calls SweepAcquired m-file, which deals with data
set(daq,'SamplesAcquiredActionCount',update)
set(daq,'StopAction','daqaction');
set(daq,'UserData',update);                 % the number of samples to acquire is stored here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = setupScope(scope, amp);
% sets up the scope properties
clearPlot(scope);
set(scope, {'XLimMode','XLim'}, {'Manual', [0 2000]});  % we'll manage the x axis ourselves.
set(scope, 'NextPlot', 'add');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
lbl = get(scope,'YLabel');
set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function [] = analyze(obj, event)
% This function gets called as a result of the SamplesAcquiredAction.  It
% retrieves the data from the DAQ engine and passes it to plotData()
samples         = get(obj,'UserData');
[data, time]    = getdata(obj, samples);
plotData(data,time)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = plotData(data, time)
global wc
index   = wc.control.amplifier.Index;
data    = data(:,index);
Scope('scope', time * 1000, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
Scope('clear');
