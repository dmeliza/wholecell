function varargout = EpisodeAnalysis(varargin)
% EpisodeAnalysis
%
% A quicky-GUI for analyzing episodic traces.  In the current revision,
% PSP (or PSC) slope, input resistance, and series resistance are extracted
% from a collection of traces.  In future versions it would be nice
% to generalize this to any filter that yields a single value from an entire
% trace.
%
% A lot of data is stored in UserData fields of various objects.
% filename.UserData - .data, .time, .abstime, .info (original .mat data)
% trace_list.UserData - handles of traces in the trace_axes
% trace_axes.UserData - abstime, binned to correspond to the traces in the axes
% (x|y)slider.UserData - original XLim and YLim of the data in trace_axes
% adjust_baseline.UserData - limits of data to be averaged for baseline
% lp_factor.UserData - original sampling rate of data
% times.UserData - times for computation marks
%
% $Id$
global wc;

if nargin > 0
	action = lower(varargin{1});
else
	action = 'standalone';
end
switch action
    
case 'standalone'
    InitWC;
    fig = OpenGuideFigure(me,'DoubleBuffer','off');
    setupFigure;
    
case 'init'
    fig = OpenGuideFigure(me,'DoubleBuffer','off');
    setupFigure;
    
case 'trace_axes_callback'
    %keyboard;
    updateSliders;
    
case 'trace_click_callback'
    % captures clicks on traces
    % left-button highlights the trace and associated values (listbox etc)
    % right button opens a trace context menu that allows deletion or more
    % complicated labelling
    v = GetUIParam(me,'select_button','Value');
    if (v > 0)
        trace = gcbo;
        % do something
    else
        % could replace this with a direct call, but we'll leave it flexible for now
        handler = GetUIParam(me,'trace_axes','ButtonDownFcn');
        eval(handler);
    end
    
case 'mark_click_callback'
    v = GetUIParam(me,'select_button','Value');
    if (v > 0)
        clickMark(gcbo);
    else
        handler = GetUIParam(me,'trace_axes','ButtonDownFcn');
        eval(handler);
    end
    
case 'load_traces_callback'
    % loads traces from a .mat file and stores them in the figure
    [fn pn] = uigetfile('*.mat');
    if (fn ~= 0)
        SetUIParam(me,'filename','String',fn);
        d = load(fullfile(pn,fn));
        SetUIParam(me,'filename','UserData',d);
        SetUIParam(me,'status','String',['Loaded data from ' fn]);
        SetUIParam(me,'last_trace','StringVal',length(d.abstime));
        SetUIParam(me,'lp_factor','StringVal',d.info.t_rate);
        SetUIParam(me,'lp_factor','UserData',d.info.t_rate);
        updateDisplay;
    end
    
    
case 'daq_converter_callback'
    % runs DAQ2MAT
    [fn pn] = uigetfile('*.daq');
    if (fn ~= 0)
        [d.data, d.time, d.abstime, d.info] = DAQ2MAT(pn);
        SetUIParam(me,'filename','UserData',d);
        SetUIParam(me,'status','String',['Loaded data from daq files']);
        updateDisplay;
    end
    
    
case 'trace_list_callback'
    % handles user selections from the trace list
    i = GetUIParam(me, 'trace_list', 'Value');
    if (i > 0)
        h = GetUIParam(me, 'trace_list', 'UserData');
        set(h,'Visible','off');
        set(h(i),'Visible','on');
    end

case 'property_changed_callback'
    % redraws the traces if the post-processing properties change
    updateDisplay;
    
case 'reset_axes_callback'
    % returns the axes to their default state
    a = GetUIHandle(me,'trace_axes');
    axis(a,'auto');
    
case 'zoom_axes_callback'
    v = GetUIParam(me,'zoom_axes','Value');
    f = findobj('tag',me);
    if (v > 0)
        SetUIParam(me,'select_button','Value',0);
        zoom(f,'on');
    else
        SetUIParam(me,'select_button','Value',1);
        zoom(f,'off');
    end
    
case 'select_button_callback'
    % other calls read this value, so the only thing to do here is turn zoom off or on
    v = GetUIParam(me,'select_button','Value');
    SetUIParam(me,'zoom_axes','Value',not(v));
    feval(me,'zoom_axes_callback');

case 'yslider_callback'
    y = GetUIParam(me,'yslider', 'Value');
    center = getCenter;
    setCenter([center(1) y])

case 'xslider_callback'
    x = GetUIParam(me,'xslider', 'Value');
    center = getCenter;
    setCenter([x center(2)])

case 'adjust_baseline_callback'
    % Adjusts the baseline of the loaded traces using values in
    % adjust_baseline.UserData
    adjustBaseline(GetUIParam(me,'adjust_baseline','UserData'));
    
case 'set_baseline_limits_callback'
    lim = GetUIParam(me,'adjust_baseline','UserData');
    % fix this later
    
case 'time_changed_callback'
    f = gcbo;
    m = get(f,'UserData');
    v = str2num(get(f,'String'));
    set(m,'XData',[v v]);
    
case 'close_callback'
    delete(gcbf);
    
end

% private functions
%
function out = me()
out = mfilename;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% these functions define a drag operation; we have to do some fancy callback
% magic
function clickMark(mark)
obj = gcf;
set(obj,'UserData',mark);
dragHandler = @dragMark;
releaseHandler = @releaseMark;
set(obj,'WindowButtonMotionFcn',dragHandler);
set(obj,'WindowButtonUpFcn',releaseHandler);
set(obj,'DoubleBuffer','on');

function dragMark(varargin)
obj = gcf;
mark = get(obj,'UserData');
pt = get(gca,'CurrentPoint');
x = pt(1);
set(mark,'XData',[x x]);
f = get(mark,'UserData');
set(f,'String',num2str(x));

function releaseMark(varargin)
obj = gcf;
set(obj,'WindowButtonMotionFcn','');
set(obj,'WindowButtonUpFcn','');
set(obj,'DoubleBuffer','off');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupFigure()
% sets up the figure's default values
SetUIParam(me,'bin_factor','String','12');
SetUIParam(me,'pspbaselinestart','String','0');
SetUIParam(me,'pspbaselineend','String','0');
SetUIParam(me,'pspslopeend','String','0');
SetUIParam(me,'resistbaselinestart','String','0');
SetUIParam(me,'resistbaselineend','String','0');
SetUIParam(me,'seriesend','String','0');
SetUIParam(me,'inputend','String','0');
SetUIParam(me,'last_trace','String','0');
SetUIParam(me,'bin_factor','String','12');
SetUIParam(me,'smooth_factor','String','1');
SetUIParam(me,'lp_factor','String','1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function varargout = updateDisplay
% processes the traces stored in the figure, binning and smoothing them
% and then plotting them in the correct axes
% 
d = GetUIParam(me,'filename','UserData');
if (isstruct(d))
    binfactor = GetUIParam(me,'bin_factor','StringVal');
    lasttrace = GetUIParam(me,'last_trace','StringVal');
    smoothfactor = GetUIParam(me,'smooth_factor','StringVal');
    lpfactor = GetUIParam(me,'lp_factor','StringVal');
    
    data = smoothTraces(d.data, smoothfactor);
    [data, abstime] = binTraces(data, d.abstime, binfactor);
    data = filterTraces(data, lpfactor);
    
    plotTraces(data, d.time, d.info, abstime);
    updateSliders;
    plotMarks;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function times = getTimes;
% returns the times from the user entry fields
times.pspbs = GetUIParam(me,'pspbaselinestart','StringVal');
times.pspbe = GetUIParam(me,'pspbaselineend','StringVal');
times.pspm = GetUIParam(me,'pspslopeend','StringVal');
times.rbs = GetUIParam(me,'resistbaselinestart','StringVal');
times.rbe = GetUIParam(me,'resistbaselineend', 'StringVal');
times.srm = GetUIParam(me,'seriesend','StringVal');
times.irm = GetUIParam(me,'inputend','StringVal');
times.curr = GetUIParam(me,'current_inj','StringVal');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function varargout = plotTraces(varargin)
% plots the traces in the trace axes, setting the correct callbacks, etc
% stores the times of the traces in UserData
% void plotTraces(data, time, info, abstime)
% void plotTraces(data, time, info) [uses existing values for abstime]
data = varargin{1};
time = varargin{2};
info = varargin{3};
if (nargin > 3)
    abstime = varargin{4};
else
    abstime = GetUIParam(me,'trace_axes','UserData');
end
a = GetUIHandle(me,'trace_axes');
axes(a);
traces = plot(time, data,'k');
xlabel(['time (' info.t_unit ')'],'FontSize', 12);
ylabel(info.y_unit, 'FontSize',12);

for i = 1:length(traces)
    click_handler = sprintf('%s(''trace_click_callback'')', me);
    set(traces,'ButtonDownFcn',click_handler);
end
set(a,'ButtonDownFcn',[me '(''trace_axes_callback'')']);
set(a, 'UserData', abstime);
% then update the trace list
SetUIParam(me,'trace_list','UserData',traces);
tr = 1:length(traces);
SetUIParam(me,'trace_list','String',num2str(tr'));
SetUIParam(me,'trace_list','Value',tr);
% store original limits in the sliders
SetUIParam(me,'xslider','UserData',GetUIParam(me,'trace_axes','XLim'));
SetUIParam(me,'yslider','UserData',GetUIParam(me,'trace_axes','YLim'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function plotMarks
% draws the mark lines (off screen) and sets up the correspondance between
% the handles of the marks and the displays.
colors = {'red','blue','black','red','blue','green','black'};
tags = {'pspbaselinestart','pspbaselineend','pspslopeend',...
        'resistbaselinestart','resistbaselineend','seriesend','inputend'};
ydim = GetUIParam(me,'yslider','UserData');
for i = 1:length(tags)
    f = findobj('tag',tags{i});
    v = str2num(get(f,'String'));
    m = get(f,'UserData');
    if (m > 1 & ishandle(m))
        delete(m);
    end
    m = line([v v], ydim);
    set(m,'Color',colors{i});
    bdfn = sprintf('%s(''%s'')',me, 'mark_click_callback');
    set(m,'ButtonDownFcn', bdfn);
    set(m,'tag',[tags{i} '_mark']);
    set(m,'UserData',f);
    set(f,'UserData',m);
    bdfn = sprintf('%s(''%s'')',me, 'time_changed_callback');
    set(f,'ButtonDownFcn', bdfn);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, abstime] = binTraces(data, abstime, binfactor)
% bins traces and times;
data = BinData(data, binfactor);
abstime = BinData(abstime, binfactor);
abstime = abstime';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function data = smoothTraces(data, smoothfactor)
% does nothing currently

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5555555
function data = filterTraces(data, lpfactor)
% does nothing at present

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function center = getCenter;
% Returns the center point of the axes
x = GetUIParam(me,'trace_axes','XLim');
y = GetUIParam(me,'trace_axes','YLim');
center = [mean(x) mean(y)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%555
function setCenter(centerPoint)
% Sets the center of the axes without zooming
x = GetUIParam(me,'trace_axes','XLim');
y = GetUIParam(me,'trace_axes','YLim');
trans = [mean(x) mean(y)] - centerPoint;
SetUIParam(me,'trace_axes','XLim', x - trans(1));
SetUIParam(me,'trace_axes','YLim', y - trans(2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%555
function updateSliders
% Sets the value of the sliders based on the axes' view
sl = GetUIHandle(me,'xslider');
lim = GetUIParam(me,'trace_axes','XLim');
updateSlider(sl, lim);
sl = GetUIHandle(me,'yslider');
lim = GetUIParam(me,'trace_axes','YLim');
updateSlider(sl, lim);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateSlider(slider, limits)
% Updates an individual slider.
% void updateSlider(slider[handle], limits[2-vector])
% limits are the current limits of the graph

dim = get(slider,'UserData');
if (diff(limits) >= diff(dim))
    set(slider, 'Enable', 'off');
else
    set(slider, 'Enable', 'on');
    set(slider, 'Min', dim(1), 'Max', dim(2), 'Value', mean(limits));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adjustBaseline(limits)
% Adjusts the baseline of the traces in the trace axes
% Uses adjust_baseline.UserData ms
d = GetUIParam(me,'filename','UserData');
th = GetUIParam(me,'trace_list','UserData'); % trace handles
ydata = get(th,'YData');
if iscell(ydata)
    data = cat(1,ydata{:});
else
    data = ydata;
end
limits = (limits * d.info.t_rate) + 1;
adj = mean(data(:,limits(1):limits(2)),2);
data = data - repmat(adj, 1, size(data,2));
plotTraces(data, d.time, d.info);
plotMarks;

% --------------------------------------------------------------------
function varargout = loadTimes_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.loadTimes.
%[pathstr,baseName,ext,versn] = fileparts(handles.filename);
[filename,path] = uigetfile('*times.csv');
if exist(filename,'file');
    times = importTimes(filename);
    setTimes(times,handles);
    updateDisplay(handles);
    setStatus(['Times loaded from ' filename],handles);
else
    setStatus(['Unable to open file: ' filename], handles);
end

% --------------------------------------------------------------------
function varargout = saveTimes_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.saveTimes.
times = getTimes(handles);
[pathstr,baseName,ext,versn] = fileparts(handles.filename);
exportTimes(times,baseName);
setStatus(['Times saved to ' baseName '_times.csv'],handles);

% --------------------------------------------------------------------
function varargout = computeStats_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.computeStats.
if (length(handles.filename) <= 0)
    setStatus('No ABF file loaded',handles);
    return;
end
times = getTimes(handles);
if (~(times.ePSPBaseline < times.endPSP & times.eResistBaseline < times.endSeries & times.eResistBaseline < times.endInput))
    setStatus('Invalid time points',handles);
    return; 
end
stats = computeStats(handles);
dispStats(handles, stats);

%---------------------------------------------------------------------
% Stub for Callback of the uicontrol handles.saveStats.
function varargout = saveStats_Callback(h, eventdata, handles, varargin)
[filename path] = uiputfile('*.csv');
[pathstr,baseName,ext,versn] = fileparts([path filename]);
stats = computeStats(handles);
exportStats(stats,[pathstr '\' baseName]);
setStatus(['Statistics saved in ' pathstr '\' baseName '.csv'], handles);

%----------------------------------------------------------------------
% my functions

% computes the statistics from the traces
% note: inter-trace interval is hard-coded
function stats = computeStats(handles)
stats = getTimeCourse(handles.traces,getTimes(handles));
stats.binFactor = str2double(get(handles.binFactor,'String'));
timeDelta = 5 * stats.binFactor;
stats.time = 1:timeDelta:(timeDelta * length(stats.psp));



% Displays the statistics
function dispStats(handles, stats)
axes(handles.pspAxes);
timeDelta = 5 * stats.binFactor;
stats.time = 1:timeDelta:(timeDelta * length(stats.psp));
scatter(stats.time,stats.psp);
ylabel('PSP Slope (mV/ms)');
yrange = get(handles.pspAxes,'YLim');
set(handles.pspAxes,'YLim',[0 yrange(2)]);
axes(handles.resistAxes);
scatter(stats.time,stats.series);
hold on;
ylabel('Resistance (mohm)');
scatter(stats.time,stats.ir,10,'filled');
xlabel('Time (s)');
hold off;
showSummary(stats, handles);

% Shows summary information
function showSummary(stats, handles)
axes(handles.pspAxes);
t = sprintf('Mean: %2.4f +/- %2.2f %%', stats.pspAvg, (stats.pspStd / stats.pspAvg * 100));
y = get(handles.pspAxes, 'YLim');
text(10, (y(2) -  y(1)) * 0.9 , t);
axes(handles.resistAxes);
t = sprintf('SR: %2.4f +/- %2.2f %%', stats.seriesAvg, (stats.seriesStd / stats.seriesAvg * 100));
y = get(handles.resistAxes, 'YLim');
text(10, (y(2) -  y(1)) * 0.8 + y(1), t);
x = get(handles.resistAxes, 'XLim');
t = sprintf('IR: %2.4f +/- %2.2f %%', stats.irAvg, (stats.irStd / stats.irAvg * 100));
text((x(2) - x(1)) * 0.8, (y(2) -  y(1)) * 0.8 + y(1), t);

% Clears the statistics window
function clearStats(handles)
axes(handles.pspAxes);
cla;
axes(handles.resistAxes);
cla;

% Returns the last trace value
function lt = getLastTrace(handles)
lt = str2double(get(handles.lastTrace,'String'));
if (~isnumeric(lt) | lt < 0)
    lt = 0;
end

% Returns the bin factor value
function bf = getBinFactor(handles)
bf = str2double(get(handles.binFactor,'String'));
if (~isnumeric(bf) | bf < 1)
    bf = 1;
end
% Returns the smoothing factor
function lt = getSmoothFactor(handles)
lt = str2double(get(handles.smoothFactor,'String'));
if (~isnumeric(lt) | lt < 0)
    lt = 1;
end
% Returns the filtering factor
function lt = getFilterFactor(handles)
lt = str2double(get(handles.filterFactor,'String'));
if (~isnumeric(lt) | lt < 0)
    lt = 1;
end
% Returns the gain correction
function lt = getGainFactor(handles)
lt = str2double(get(handles.gainFactor,'String'));
if (~isnumeric(lt) | lt < 0)
    lt = 1;
end

% (re)draws traces
function handles = drawTraces(handles)
handler = get(handles.axes1,'ButtonDownFcn');
handles.traceHandles = dispTraces(handles.pc8h,handles.traces,handles.axes1);
fillList(size(handles.traces),handles);
handles.origX = get(handles.axes1,'XLim');
handles.origY = get(handles.axes1,'YLim');
updateSliders(handles);
handles.marks = drawMarks(handles, handler);
zoom on;
set(handles.traceHandles,'ButtonDownFcn',handler);
set(handles.axes1,'ButtonDownFcn',handler);
set(handles.fileName,'String',handles.filename);



% Generates new mark lines according to values in entry fields
function marks = drawMarks(handles, clickHandler)
axes(handles.axes1);
times = getMarks(handles);
ydim = get(handles.axes1,'YLim');
marks.pspbaselinestart = line([times.sPSPBaseline times.sPSPBaseline], ydim);
set(marks.pspbaselinestart, 'ButtonDownFcn', clickHandler);
set(marks.pspbaselinestart, 'Color', 'red');
marks.pspbaselineend = line([times.ePSPBaseline times.ePSPBaseline], ydim);
set(marks.pspbaselineend, 'ButtonDownFcn', clickHandler);
set(marks.pspbaselineend, 'Color', 'blue');
marks.pspslopeend = line([times.endPSP times.endPSP], ydim);
set(marks.pspslopeend, 'ButtonDownFcn', clickHandler);
set(marks.pspslopeend, 'Color', 'black');
marks.resistbaselinestart = line([times.sResistBaseline times.sResistBaseline], ydim);
set(marks.resistbaselinestart, 'ButtonDownFcn', clickHandler);
set(marks.resistbaselinestart, 'Color', 'red');
marks.resistbaselineend = line([times.eResistBaseline times.eResistBaseline], ydim);
set(marks.resistbaselineend, 'ButtonDownFcn', clickHandler);
set(marks.resistbaselineend, 'Color', 'blue');
marks.seriesend = line([times.endSeries times.endSeries], ydim);
set(marks.seriesend, 'ButtonDownFcn', clickHandler);
set(marks.seriesend, 'Color', 'green');
marks.inputend = line([times.endInput times.endInput], ydim);
set(marks.inputend, 'ButtonDownFcn', clickHandler);
set(marks.inputend, 'Color', 'black');

% fills text fields with times data
function setTimes(times,handles)
set(handles.pspbaselinestart,'String',num2str(times.sPSPBaseline));
set(handles.pspbaselineend,'String',num2str(times.ePSPBaseline));
set(handles.pspslopeend,'String',num2str(times.endPSP));
set(handles.resistbaselinestart,'String',num2str(times.sResistBaseline));
set(handles.resistbaselineend,'String',num2str(times.eResistBaseline));
set(handles.seriesend,'String',num2str(times.endSeries));
set(handles.inputend,'String',num2str(times.endInput));
set(handles.currentInj,'String',num2str(times.currentInjection));

% updates the marks
function updateMarks(handles)
x = str2double(get(handles.inputend,'String'));
set(handles.marks.inputend,'XData',[x x]);
x = str2double(get(handles.pspbaselinestart,'String'));
set(handles.marks.pspbaselinestart,'XData',[x x]);
x = str2double(get(handles.pspbaselineend,'String'));
set(handles.marks.pspbaselineend,'XData',[x x]);
x = str2double(get(handles.pspslopeend,'String'));
set(handles.marks.pspslopeend,'XData',[x x]);
x = str2double(get(handles.resistbaselinestart,'String'));
set(handles.marks.resistbaselinestart,'XData',[x x]);
x = str2double(get(handles.resistbaselineend,'String'));
set(handles.marks.resistbaselineend,'XData',[x x]);
x = str2double(get(handles.seriesend,'String'));
set(handles.marks.seriesend,'XData',[x x]);

