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
update = fix(sr / 20); % update at 20 Hz
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
set(scope, {'YLimMode','YLim'}, {'Manual', [-2 2]});  % for now, before we figure out how to change this in the GUI
%set(scope,'XLimMode','Auto','YLimMode','auto');
set(scope, 'NextPlot', 'add');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
lbl = get(scope,'YLabel');
set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(data, time, index)
% Handles data plotting and scrolling.  There are two tasks to take care of:
%1: if a plot crosses XLim, it needs to be broken in two and the part that crosses plotted at 0
%2: if a plot overlaps with another plot, the prior plot needs to be deleted
%   Because all plots are the same length condition 2 can be detected at the endpoints.
% finally, we have to keep track of where to plot things, so the endpoint of the last plot
% is stored in wc.gapfree.offset
global wc

scope = getScope; % this might be a slowdown
data = data(:,index);
%SetUIParam('wholecell','progress','String',num2str(time(1)));
time = (time - time(1)) * 1000 + wc.gapfree.offset;
% Condition 1: bounds overstep - move data to beginning of plot
xlim = get(scope, 'XLim');
i = find(time >= xlim(2));
if (~isempty(i))
    time = time - time(1);
end
% We find the closest index for the start of our time vector and replace the y values with
% our data set
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
%plot(time(1),data(1),'parent', scope);
wc.gapfree.offset = time(length(time));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
kids = get(axes, 'Children');
delete(kids);

%condition 2 now implemented by directly editing the datasets of the plot
% k = get(scope,'Children');
% if (isempty(k))
%     plot(time, data, 'Parent', scope);
% else
%     t = get(k,'XData');
%     y = get(k,'YData');
%     o = find(t >= time(1));
%     o = o(1):o(1)+length(time)-1;
%     t(o) = time;
%     y(o) = data;
%     plot(t,y,'Parent',scope);
% end
