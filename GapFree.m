function varargout = GapFree(varargin)
% a simple gapfree protocol.  Acquires data from the DAQ from time to time
% and updates the scope.
%
% void GapFree(action,[options])
% action can be 'start', 'stop', or 'record'
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
    % these are here in case the user loads GapFree as a protocol
    
case 'start'
    setupScope(wc.wholecell.handles.scope, wc.control.amplifier);
    setupHardware(wc.control.amplifier);
    StartAcquisition(me,wc.ai);
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        stop(wc.ai);
    end
    setupScope(wc.wholecell.handles.scope, wc.control.amplifier);
    setupHardware(wc.control.amplifier);
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Index'});
    StartAcquisition(me,wc.ai);
    
case 'stop'
    StopAcquisition(me,wc.ai);
    set(wc.ai,'LoggingMode','Memory');
    
case 'sweep'
    data = varargin{2};
    time = varargin{3};
    plotData(data, time, wc.wholecell.handles.scope, wc.control.amplifier.Index);
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupHardware(amp)
% Sets up the hardware for this mode of acquisition
global wc

daq = amp.Parent;
sr = get(daq, 'SampleRate');
update = fix(sr / 20); % update at 5 Hz
set(daq,'SamplesPerTrigger',inf);
set(daq,'SamplesAcquiredAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data
set(daq,'SamplesAcquiredActionCount',update)
set(daq,'StopAction','daqaction');
% may need to turn ManualTriggerHwOn to Start, in which case we need to make sure we put it back
wc.control.pulse = zeros(1,update); % this is a kludge to get around how SweepAcquired knows how much data to ask for
wc.gapfree.offset = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupScope(scope, amp);
% sets up the scope properties
clearPlot(scope);
set(scope, {'XLimMode','XLim'}, {'Manual', [0 2000]});  % we'll manage the x axis ourselves.
set(scope, 'YLim', [-3 3]);  % for now, before we figure out how to change this in the GUI
set(scope, 'NextPlot', 'add');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
lbl = get(scope,'YLabel');
set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(data, time, scope, index)
% Handles data plotting and scrolling.  There are two tasks to take care of:
%1: if a plot crosses XLim, it needs to be broken in two and the part that crosses plotted at 0
%2: if a plot overlaps with another plot, the prior plot needs to be deleted
%   Because all plots are the same length condition 2 can be detected at the endpoints.
% finally, we have to keep track of where to plot things, so the endpoint of the last plot
% is stored in wc.gapfree.offset
global wc

data = data(:,index);
SetUIParam('wholecell','progress','String',num2str(time(1)));
time = (time - time(1)) * 1000 + wc.gapfree.offset;
% Condition 1: bounds overstep - move data to beginning of plot
xlim = get(scope, 'XLim');
i = find(time >= xlim(2));
if (~isempty(i))
    time = time - time(1);
end
% condition 2: overlap with plot
kids = get(scope,'Children');
if (~isempty(kids))
    xdata = get(kids,'XData');
    if (iscell(xdata))
        used = cat(1,xdata{:});
    else
        used = xdata;
    end
    % create a column vector of booleans
    minmax = [used(:,1), used(:,size(used,2))];
    s = (time(2) > minmax(:,1)) & (time(2) < minmax(:,2));
    e = (time(length(time)) > minmax(:,1)) & (time(length(time)) < minmax(:,2));
    delete(kids(find(s)));
    delete(kids(find((e - s)>0))); % the minus avoids deleting handles already deleted
end
    
% plot data (finally) and set offset for next plot
plot(time, data, 'Parent', scope);
wc.gapfree.offset = time(length(time));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
kids = get(axes, 'Children');
delete(kids);