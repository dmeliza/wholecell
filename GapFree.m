function varargout = GapFree(varargin)
% a simple gapfree protocol.  Acquires data from the DAQ from time to time
% and updates the scope.
%
% void GapFree(action,[options])
% action can be 'start', 'stop', or 'record'
%
%
%
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
    Scope('init');
    
case 'start'
    scope = getScope;
    setupScope(scope, wc.control.amplifier);
    setupHardware(wc.control.amplifier);
    SetUIParam('scope','status','String','Not recording');
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
    SetUIParam('scope','status','String',lf);
    StartAcquisition(me,wc.ai);
    
case 'stop'
    StopAcquisition(me,wc.ai);
    if (isvalid(wc.ai))
        set(wc.ai,'LoggingMode','Memory');
    end
    
case 'sweep'
    in = get(wc.ai,'SamplesAvailable');
    out = get(wc.ao,'SamplesAvailable');
    status = sprintf('in: %d / out: %d',in, out); 
    SetUIParam('scope','status','String',status);    
    plotData(varargin{2}, varargin{3}, wc.control.amplifier.Index);
    
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
function varargout = setupHardware(amp)
% Sets up the hardware for this mode of acquisition
global wc

daq = amp.Parent;
sr = get(daq, 'SampleRate');
update = fix(sr / 10); % update at 20 Hz
set(daq,'SamplesPerTrigger',inf);
set(daq,'SamplesAcquiredAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data
set(daq,'SamplesAcquiredActionCount',update)
set(daq,'StopAction','daqaction');
% may need to turn ManualTriggerHwOn to Start, in which case we need to make sure we put it back
set(daq,'UserData',update);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupScope(scope, amp);
% sets up the scope properties
clearPlot(scope);
set(scope, {'XLimMode','XLim'}, {'Manual', [0 2000]});  % we'll manage the x axis ourselves.
%set(scope, {'YLimMode','YLim'}, {'Manual', [-2 2]});  % for now, before we figure out how to change this in the GUI
%set(scope,'XLimMode','Auto','YLimMode','auto');
set(scope, 'NextPlot', 'add');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
lbl = get(scope,'YLabel');
set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(data, time, index)
global wc
data = data(:,index);
Scope('scope', time * 1000, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
Scope('clear');
