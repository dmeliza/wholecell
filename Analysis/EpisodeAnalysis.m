function varargout = EpisodeAnalysis(varargin)
% EpisodeAnalysis
%
% A quicky-GUI for analyzing episodic traces.  In the current revision,
% PSP (or PSC) slope, input resistance, and series resistance are extracted
% from a collection of traces.  In future versions it would be nice
% to generalize this to any filter that yields a single value from an entire
% trace.
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
    %updateSliders;
    
case 'trace_click_callback'
    % captures clicks on traces
    v = GetUIParam(me,'select_button','Value');
    if (v > 0)
        trace = varargin{2};
        % do something
    else
        % could replace this with a direct call, but we'll leave it flexible for now
        handler = GetUIParam(me,'trace_axes','ButtonDownFcn');
        eval(handler);
    end
    
case 'mark_click_callback'
    v = GetUIParam(me,'select_button','Value');
    if (v > 0)
        mark = varargin{2};
        % do something
    else
        handler = GetUIParam(me,'trace_axes','ButtonDownFcn');
        feval(handler);
    end
    
case 'load_traces_callback'
    % loads traces from a .mat file and stores them in the figure
    [fn pn] = uigetfile('*.mat');
    if (fn ~= 0)
        SetUIParam(me,'filename','String',fn);
        d = load(fullfile(pn,fn));
        SetUIParam(me,'filename','UserData',d);
        SetUIParam(me,'status','String',['Loaded data from ' fn]);
        updateDisplay;
    end
    
    
case 'daq_converter_callback'
    % runs DAQ2MAT
    [d.data, d.time, d.abstime, d.info] = DAQ2MAT;
    SetUIParam(me,'filename','UserData',d);
    SetUIParam(me,'status','String',['Loaded data from daq files']);
    
    updateDisplay;
    
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
    center = getCenter(handles)
    setCenter([center(1) y])
        
case 'close_callback'
    delete(gcbf);
    
end

% private functions
%
function out = me()
out = mfilename;
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
SetUIParam(me,'lastTrace','String','0');
SetUIParam(me,'binFactor','String','12');
SetUIParam(me,'smoothFactor','String','1');
SetUIParam(me,'filterFactor','String','1');

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
    
    plotTraces(data, d.time, abstime, d.info);
    %plotMarks;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function varargout = plotTraces(data, time, abstime, info)
% plots the traces in the trace axes, setting the correct callbacks, etc
% stores the times of the traces in UserData
a = GetUIHandle(me,'trace_axes');
axes(a);
traces = plot(time, data);
xlabel(['time (' info.t_unit ')'],'FontSize', 12);
ylabel(info.y_unit, 'FontSize',12);

for i = 1:length(traces)
    click_handler = sprintf('%s(''trace_click_callback'',%i)', me, traces(i));
    set(traces,'ButtonDownFcn',click_handler);
end
set(a,'ButtonDownFcn',[me '(''trace_axes_callback'')']);
set(a, 'UserData', abstime);
% then update the trace list
SetUIParam(me,'trace_list','UserData',traces);
tr = 1:length(traces);
SetUIParam(me,'trace_list','String',num2str(tr'));
SetUIParam(me,'trace_list','Value',tr);


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
% Returns the center point of the axes
function center = getCenter;
a = findobj('tag','trace_axes');
v = axis(a);
center = [mean(a(1:2)) mean(a(3:4))];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%555
% Sets the center of the axes without zooming
function setCenter(centerPoint)
a = findobj('tag','trace_axes');
v = axis(a);
trans = [mean(a(1:2)) mean(a(3:4))] - centerPoint;
axis(a,[xdim - trans(1), ydim - trans(2)]);

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

% Stub for Callback of the uicontrol handles.adjustBaseline.
function varargout = adjustBaseline_Callback(h, eventdata, handles, varargin)
adjustBaseline(handles);

%----------------------------------------------------------------------
% my functions

% computes the statistics from the traces
% note: inter-trace interval is hard-coded
function stats = computeStats(handles)
stats = getTimeCourse(handles.traces,getTimes(handles));
stats.binFactor = str2double(get(handles.binFactor,'String'));
timeDelta = 5 * stats.binFactor;
stats.time = 1:timeDelta:(timeDelta * length(stats.psp));

% Adjusts the baseline of the loaded traces
% uses the first 5 ms
function adjustBaseline(handles)
traces = handles.traces;
delta = 5 * ceil(1000 / handles.pc8h.fADCSampleInterval);
handles.traces = traces - repmat(mean(traces(10:delta,:)),size(traces,1),1);
handles = drawTraces(handles);
guidata(gcbo,handles);

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

% plots traces with correct units
% traces - columnwise data
% returns handles to the trace objects
function handles = dispTraces(pc8h,traces,axesHandle)
axes(axesHandle);
sampleInt = pc8h.fADCSampleInterval / 1000;
sampleUnit = 'ms';
sweepInt = size(traces,1) * sampleInt;
time = 0:sampleInt:(sweepInt-sampleInt);
handles = plot(time(:),traces);
xlabel(['time (' sampleUnit  ')'],'FontSize',12);
ylabel('Vm (mV)', 'FontSize', 12);

% Generates a list corresponding to the traces
function fillList(traceCount,handles)
traces = 1:traceCount(2);
set(handles.traceList,'String',num2str(traces(:)));
set(handles.traceList,'Value',traces);

% retrieves a partial time struct
function times = getMarks(handles)
times.sPSPBaseline = str2double(get(handles.pspbaselinestart,'String'));
times.ePSPBaseline = str2double(get(handles.pspbaselineend,'String'));
times.endPSP = str2double(get(handles.pspslopeend,'String'));
times.sResistBaseline = str2double(get(handles.resistbaselinestart,'String'));
times.eResistBaseline = str2double(get(handles.resistbaselineend,'String'));
times.endSeries = str2double(get(handles.seriesend,'String'));
times.endInput = str2double(get(handles.inputend,'String'));

% Returns the times structure from the text entry fields
function times = getTimes(handles)
times = getMarks(handles);
times.sampleInterval = handles.pc8h.fADCSampleInterval / 1000;
times.currentInjection = str2double(get(handles.currentInj,'String'));

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

% Sets the value of the sliders based on the axes' view
function updateSliders(handles)
dim = handles.origX;
sel = get(handles.axes1,'XLim');
range = (sel(2) - sel(1));
if (sel >= dim)
    set(handles.xSlider, 'Enable', 'off');
else
    set(handles.xSlider, 'Enable', 'on');
    set(handles.xSlider, 'Min', dim(1), 'Max', dim(2), 'Value', sel(1) + range / 2);
    %set(handles.xSlider, 'SliderStep', [0.1 0.5]);
end
dim = handles.origY;
sel = get(handles.axes1,'YLim');
range = (sel(2) - sel(1));
if (sel >= dim)
    set(handles.ySlider, 'Enable', 'off');
else
    set(handles.ySlider, 'Enable', 'on');
    set(handles.ySlider, 'Min', dim(1), 'Max', dim(2), 'Value', sel(1) + range / 2);
    %set(handles.ySlider, 'SliderStep', [0.1 0.5]);
end

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

% --------------------------------------------------------------------
function varargout = ySlider_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.slider2.

% --------------------------------------------------------------------
function varargout = xSlider_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.slider3.
x = get(handles.xSlider, 'Value');
center = getCenter(handles);
setCenter(handles, [x center(2)]);

% --------------------------------------------------------------------
function varargout = filterFactor_Callback(h, eventdata, handles, varargin)
reloadABF_Callback(h, eventdata, handles, varargin);

% --------------------------------------------------------------------
function varargout = gainFactor_Callback(h, eventdata, handles, varargin)
reloadABF_Callback(h, eventdata, handles, varargin);

% --------------------------------------------------------------------
function varargout = exit_Callback(h, eventdata, handles, varargin)
close;