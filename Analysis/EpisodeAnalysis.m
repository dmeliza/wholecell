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
        traces = GetUIParam(me,'trace_list','UserData');
        highlightTrace(find(traces==trace));
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

case 'stats_click_callback'
    % figure out the index of the patch clicked, then highlight
    patch = gcbo;
    t = get(patch,'XData');
    abstime = GetUIParam(me,'psp_traces','UserData');
    traceindex = find(abstime==t);
    highlightTrace(traceindex);
    
case 'load_traces_callback'
    % loads traces from a .mat file and stores them in the figure
    [fn pn] = uigetfile('*.mat');
    if (fn ~= 0)
        SetUIParam(me,'filename','String',fullfile(pn,fn));
        d = load(fullfile(pn,fn));
        SetUIParam(me,'filename','UserData',d);
        SetUIParam(me,'status','String',['Loaded data from ' fn]);
        SetUIParam(me,'last_trace','StringVal',length(d.abstime));
        SetUIParam(me,'lp_factor','StringVal',d.info.t_rate);
        SetUIParam(me,'lp_factor','UserData',d.info.t_rate);
        if (isfield(d.info,'binfactor'))
            SetUIParam(me,'bin_factor','StringVal',d.info.binfactor);
        end
        updateDisplay;
        if (isfield(d,'times'))
            setTimes(d.times);
        end
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
    set(gcf,'DoubleBuffer','on');
    set(m,'XData',[v v]);
    set(gcf,'DoubleBuffer','off');
    updateStats;
    
case 'load_times_callback'
    [fn pn] = uigetfile('*.mat');
    if exist(fullfile(pn,fn), 'file');
        d = load(fullfile(pn,fn));
        if (isfield(d,'times'))
            setTimes(d.times);
            SetUIParam(me,'status','String',['Times loaded from ' fn]);
        else
            SetUIParam(me,'status','String','Invalid .mat file');
        end
    else
        SetUIParam(me,'status','String',['Unable to open file: ' filename]);
    end
    
case 'export_times_callback'
    [fn pn] = uiputfile('*.mat');
    if (fn ~= 0)
        times = getTimes;
        save(fullfile(pn,fn), 'times');
    end
    
case 'export_stats_callback'
    [fn pn] = uiputfile('*.csv');
    if (fn ~= 0)
        [pspdata, srdata, irdata, abstime] = updateStats;
        csvwrite(fullfile(pn,fn), cat(2,abstime',pspdata',srdata',irdata'));
        SetUIParam(me,'status','String',['Statistics exported to ' fullfile(pn,fn)]);
    end
    
case 'save_analysis_callback'
    % stores a complete analysis in one file
    [fn pn] = uiputfile('*.mat');
    if (fn ~=0)
        d = GetUIParam(me,'filename','UserData');
        time = d.time;
        info = d.info;
        info.binfactor = 1;
        data = getData;
        [pspdata, srdata, irdata, abstime] = updateStats;
        times = getTimes;
        save(fullfile(pn,fn),'data','time','abstime','info','pspdata',...
            'srdata','irdata','times');
    end
    
case 'close_callback'
    delete(gcbf);

otherwise
    disp([action ' not supported']);
    
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
updateStats;

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
    updateStats;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function times = getTimes
% returns the times from the user entry fields
times.pspbs = GetUIParam(me,'pspbaselinestart','StringVal');
times.pspbe = GetUIParam(me,'pspbaselineend','StringVal');
times.pspm = GetUIParam(me,'pspslopeend','StringVal');
times.rbs = GetUIParam(me,'resistbaselinestart','StringVal');
times.rbe = GetUIParam(me,'resistbaselineend', 'StringVal');
times.srm = GetUIParam(me,'seriesend','StringVal');
times.irm = GetUIParam(me,'inputend','StringVal');
times.curr = GetUIParam(me,'current_inj','StringVal');

function setTimes(times)
% sets times in the fields and marks according to an input structure
% fills text fields with times data
SetUIParam(me,'pspbaselinestart','StringVal', times.pspbs);
SetUIParam(me,'pspbaselineend','StringVal', times.pspbe);
SetUIParam(me,'pspslopeend','StringVal', times.pspm);
SetUIParam(me,'resistbaselinestart','StringVal', times.rbs);
SetUIParam(me,'resistbaselineend', 'StringVal', times.rbe);
SetUIParam(me,'seriesend','StringVal', times.srm);
SetUIParam(me,'inputend','StringVal', times.irm);
SetUIParam(me,'current_inj','StringVal', times.curr);
plotMarks;
updateStats;

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
function plotMarks()
% draws the mark lines (off screen) and sets up the correspondance between
% the handles of the marks and the displays.
colors = {'red','blue','black','magenta','cyan','green','yellow'};
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
    SetUIParam(me,[tags{i} '_txt'],'ForegroundColor',colors{i});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function [pspdata, srdata, irdata, abstime] = updateStats()
% this method updates the statistics display using the times data
% and the traces in the window. Deleted traces are ignored, but hidden ones
% are included.  This method should be safe to call at any time, even
% if the times are invalid.
d = GetUIParam(me,'filename','UserData');
times = getTimes;
[data, abstime] = getData;
tracehandles = GetUIParam(me, 'trace_list', 'UserData');
dt = 1 / d.info.t_rate;
w = warning('off');
pspdata = ComputeSlope(data, [times.pspbs times.pspbe], times.pspm, dt) / 1000;
srdata = ComputeDiff(data, [times.rbs times.rbe], times.srm, dt) / times.curr;
irdata = ComputeDiff(data, [times.rbs times.rbe], times.irm, dt) / times.curr;
warning(w);
% plot it
a = GetUIHandle(me,'psp_axes');
clearAxes(a);
ph = scatter(abstime, pspdata);
ylabel('PSP Slope (mV/ms)');

a = GetUIHandle(me,'resist_axes');
clearAxes(a);
sh = scatter(abstime, srdata);
ih = scatter(abstime, irdata,'*');
set([ph ih sh], 'ButtonDownFcn',[me '(''stats_click_callback'')'],'EdgeColor','black');
xlabel('Time (min)'),ylabel('R (M\Omega)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clearAxes(axes_handle)
axes(axes_handle);
cla;
set(axes_handle,'NextPlot','Add');


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
data = getData;
limits = (limits * d.info.t_rate) + 1;
adj = mean(data(limits(1):limits(2),:),1);
data = data - repmat(adj, size(data,1),1);
plotTraces(data, d.time, d.info);
plotMarks;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, abstime] = getData()
% this function extracts (binned) Y data from the trace axes
% and the associated binned relative start times
tracehandles = GetUIParam(me, 'trace_list', 'UserData');
ydata = get(tracehandles,'YData');
if iscell(ydata)
    data = cat(1,ydata{:});
else
    data = ydata;
end
data = data';
abstime = GetUIParam(me,'trace_axes','UserData');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function highlightTrace(traceindex)
% this function changes the trace's state from normal to highlighted
% in four places: (the trace list), the trace axes, the psp statistics,
% and the (resistance stats)
if isempty(traceindex)
    return;
end
tracehandles = GetUIParam(me, 'trace_list', 'UserData');
trace = tracehandles(traceindex);
currentcolor = get(trace,'UserData');
if (strcmp(currentcolor,'red'))
    newcolor = 'black';
else
    newcolor = 'red';
end
set(trace,'Color',newcolor,'UserData',newcolor);
psp_patches = GetUIParam(me, 'psp_axes', 'Children');
set(psp_patches(traceindex),'EdgeColor',newcolor,'UserData',newcolor);

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


