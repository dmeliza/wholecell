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
% trace_axes.UserData - the trace structure array, which contains
%   .handle - the handle of the trace
%   .abstime, binned to correspond to the traces in the axes
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
    fig = OpenGuideFigure(me,'DoubleBuffer','on');
    setupFigure;
    
case 'init'
    fig = OpenGuideFigure(me,'DoubleBuffer','on');
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
        highlightTrace(gcbo);
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
    pnfn = GetUIParam(me,'filename','String');
    path = fileparts(pnfn);
    [fn pn] = uigetfile([path filesep '*.mat']);
    if (fn ~= 0)
        wait('Loading data...');
        SetUIParam(me,'filename','String',fullfile(pn,fn));
        d = load(fullfile(pn,fn));
        if ~isfield(d,'abstime')
            wait('Invalid .mat file');
            return;
        end
        SetUIParam(me,'filename','UserData',d);
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
        wait(['Loaded data from ' fn]);
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
    i = str2num(GetUIParam(me, 'trace_list', 'Selected'));
    showTraces(i);
    
case 'delete_trace_callback'
    % deletes selected traces in the trace window
    i = str2num(GetUIParam(me, 'trace_list', 'Selected'));
    deleteTrace(i);
    i = str2num(GetUIParam(me, 'trace_list', 'Selected'));
    showTraces(i);
    updateStats;
    
case 'color_trace_callback'
    % retrieves current color of trace(s)
    % allows user to set a new color
    i = str2num(GetUIParam(me, 'trace_list', 'Selected'));
    h = getTraces(i);
    c = get(h(1),'Color');
    c = uisetcolor(c);
    set(h,'Color',c);
    updateStats;
    
case 'save_trace_callback'
    % saves the selected traces to a new file
    pnfn = GetUIParam(me,'filename','String');
    path = fileparts(pnfn);  
    [fn pn] = uiputfile([path filesep '*.mat']);
    if (fn ~= 0)
        traces = str2num(GetUIParam(me,'trace_list','Selected'));
        saveData(fullfile(pn,fn), traces);
    end
    
case 'property_changed_callback'
    % redraws the traces if the post-processing properties change
    updateDisplay;
    
case 'reset_axes_callback'
    % returns the axes to their default state
    a = GetUIHandle(me,'trace_axes');
    axis(a,'auto');
    updateSlider;
    
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
    % adjustBaseline(GetUIParam(me,'adjust_baseline','UserData'));
    times = getTimes;
    if times.pspbs > 0 & times.pspbe > times.pspbs
        adjustBaseline([times.pspbs, times.pspbe]);
    else
        adjustBaseline(GetUIParam(me,'adjust_baseline','UserData'));
    end
    
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
    pnfn = GetUIParam(me,'filename','String');
    path = fileparts(pnfn);
    [fn pn] = uigetfile([path filesep '*.mat']);
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
    pnfn = GetUIParam(me,'filename','String');
    path = fileparts(pnfn);  
    [fn pn] = uiputfile([path filesep '*.mat']);
    if (fn ~= 0)
        times = getTimes;
        save(fullfile(pn,fn), 'times');
    end
    
case 'export_stats_callback'
    pnfn = GetUIParam(me,'filename','String');
    path = fileparts(pnfn);  
    [fn pn] = uiputfile([path filesep '*.csv']);
    if (fn ~= 0)
        wait('Writing statistics...');
        [pspdata, srdata, irdata, abstime] = getStats;
        csvwrite(fullfile(pn,fn), cat(2,abstime',pspdata',srdata',irdata'));
        wait(['Statistics exported to ' fullfile(pn,fn)]);
    end
    
case 'save_analysis_callback'
    % stores a complete analysis in one file
    pnfn = GetUIParam(me,'filename','String');
    path = fileparts(pnfn);  
    [fn pn] = uiputfile([path filesep '*.mat']);
    if (fn ~=0)
        wait('Writing file...');
        saveData(fullfile(pn,fn));
        wait(['Data written to ' fullfile(pn,fn)]);
    end
    
case 'align_episodes_callback'
    % calls AlignEpisodes on the complete data set
    d = GetUIParam(me,'filename','UserData');
    wait('Aligning episodes...');
    [d.data d.time] = AlignEpisodes(d.data, d.time, 1000:5000);
    SetUIParam(me,'filename','UserData',d);
    updateDisplay;
    wait('Episodes realigned.');
    
case 'rescale_traces_callback'
    d = GetUIParam(me,'filename','UserData');
    if ~isempty(d)
        y_unit = d.info.y_unit;
        a = inputdlg({'Data scaling factor:','Units:'},'Data Rescaling',...
            1,{'1', y_unit});
        wait('Scaling data');
        if length(a) == 2
            s = str2num(a{1});
            if isnumeric(s)
                d.data = d.data * s;
            end
            if ~isempty(a{2})
                d.info.y_unit = a{2};
            end
            SetUIParam(me,'filename','UserData',d);
            updateDisplay;
        end
        wait('Data rescaled...');
    end
    
case 'display_stats_callback'
    disp = GetUIParam(me,'display_stats','Value');
    if boolean(disp)
        updateStats;
    else
        clearAxes(GetUIHandle(me,'psp_axes'));
        clearAxes(GetUIHandle(me,'resist_axes'));
    end
    
case {'invert_stats_callback', 'show_selected_callback'}
    updateStats;
    
case 'show_marks_callback'
    v = GetUIParam(me,'show_marks','Value');
    marks = findobj('ButtonDownFcn','episodeanalysis(''mark_click_callback'')'); 
    if boolean(v)
        set(marks,'Visible','On');
    else
        set(marks,'Visible','Off');
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
SetUIParam(me,'display_stats','Value',0);
SetUIParam(me,'invert_stats','Value',0);
SetUIParam(me,'show_marks','Value',1);

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
    
    if (lasttrace > binfactor & lasttrace < length(d.abstime))
        data = d.data(:,1:lasttrace);
        abstime = d.abstime(:,1:lasttrace);
    else
        data = d.data;
        abstime = d.abstime;
        SetUIParam(me,'last_trace','StringVal',length(d.abstime));
    end
    if binfactor > size(data,2)
        binfactor = size(data,2);
        SetUIParam(me,'bin_factor','StringVal', binfactor);
    end
    data = smoothTraces(data, smoothfactor);
    [data, abstime] = binTraces(data, abstime, binfactor);
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
function varargout = plotTraces(data, time, info, abstime)
% plots the traces in the trace axes, setting the correct callbacks, etc
% stores the times of the traces in UserData
% void plotTraces(data, time, info, abstime)

a = GetUIHandle(me,'trace_axes');
axes(a);
traces = plot(time, data,'k');
xlabel(['time (' info.t_unit ')'],'FontSize', 12);
ylabel(info.y_unit, 'FontSize',12);

trace = struct([]); % the empty trace struct
for i = 1:length(traces)
    trace(i).handle = traces(i);
    trace(i).abstime = abstime(i);
end

click_handler = sprintf('%s(''trace_click_callback'')', me);
set(traces,'ButtonDownFcn',click_handler);
set(a,'ButtonDownFcn',[me '(''trace_axes_callback'')']);
set(a, 'UserData', trace);
% then update the trace list
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
    g = GetUIHandle(me,'trace_axes');
    m = line([v v], ydim, 'Parent', g,'LineStyle',':');
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function [pspdata, srdata, irdata, abstime, color] = getStats(varargin)
d = GetUIParam(me,'filename','UserData');
times = getTimes;
if nargin > 0
    [data, abstime, color] = getData(varargin{1});
else
    [data, abstime, color] = getData;
end
dt = 1 / d.info.t_rate;
w = warning('off');
pspdata = ComputeSlope(data, [times.pspbs times.pspbe], times.pspm, dt) / 1000;
srdata = ComputeDiff(data, [times.rbs times.rbe], times.srm, dt) / times.curr;
irdata = ComputeDiff(data, [times.rbs times.rbe], times.irm, dt) / times.curr;
invert = GetUIParam(me,'invert_psp','Value');
if boolean(invert)
    pspdata = -pspdata;
end
warning(w);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function updateStats()
% this method updates the statistics display using the times data
% and the traces in the window. Deleted traces are ignored, but hidden ones
% are included.  This method should be safe to call at any time, even
% if the times are invalid.

disp = GetUIParam(me,'display_stats','Value');
if ~boolean(disp)
    return;
end
wait;
S = 50;
show = GetUIParam(me,'show_selected','Value');
if boolean(show)
    traces = str2num(GetUIParam(me,'trace_list','Selected'));
    [pspdata, srdata, irdata, abstime, color] = getStats(traces);
else
    [pspdata, srdata, irdata, abstime, color] = getStats;
end


% plot it
a = GetUIHandle(me,'psp_axes');
clearAxes(a);
ph = scatter(abstime, pspdata, S, color);
ylabel('PSP Slope (mV/ms)');

a = GetUIHandle(me,'resist_axes');
clearAxes(a);
sh = scatter(abstime, irdata, S, color);
ih = scatter(abstime, srdata, S, color, '*');
set([ph ih sh], 'ButtonDownFcn',[me '(''stats_click_callback'')']);
xlabel('Time (min)'),ylabel('R (M\Omega)');
showSummary(pspdata, irdata, srdata, abstime);
wait;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clearAxes(axes_handle)
axes(axes_handle);
cla;
set(axes_handle,'NextPlot','Add');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, abstime] = binTraces(data, abstime, binfactor)
% bins traces and times;
if (binfactor > 1)
    data = BinData(data, binfactor);
    abstime = BinData(abstime, binfactor);
    abstime = abstime';
end

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
wait('Adjusting baseline...');
d = GetUIParam(me,'filename','UserData');
limits = (limits * d.info.t_rate) + 1;
adj = mean(d.data(limits(1):limits(2),:),1);
d.data = d.data - repmat(adj, size(d.data,1),1);
SetUIParam(me,'filename','UserData',d);
updateDisplay;
wait('Baseline adjusted.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, abstime, color] = getData(varargin)
% this function extracts (binned) Y data from the trace axes
% and the associated binned relative start times
% getData() - data from all traces
% getData(tracenums) - data from specific trace numbers
trace = GetUIParam(me,'trace_axes','UserData');
tracehandles = [trace.handle];
abstime = [trace.abstime]';
ydata = get(tracehandles,'YData');
if iscell(ydata)
    data = cat(1,ydata{:});
else
    data = ydata;
end
color = get(tracehandles,'Color');
if iscell(color)
    color = cat(1,color{:});
end
if nargin > 0
    traces = varargin{1};
    data = data(traces,:);
    abstime = abstime(traces);
    color = color(traces,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function h = getTraces(varargin)
% retrieves a trace handle by number (or all trace handles)
% works with arrays (if you don't go out of bounds)
tr = GetUIParam(me, 'trace_axes', 'UserData');
if nargin == 0
    h = [tr.handle];
else
    h = [tr(varargin{1}).handle];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function showTraces(tracenum)
% displays a subset of the traces
h = getTraces;
set(h,'Visible','off');
set(h(tracenum),'Visible','on');
updateStats;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function deleteTrace(tracenum)
% deletes a trace from various locations
% works with arrays if you don't go out of bounds
tr = GetUIParam(me,'trace_axes', 'UserData');
% delete traces (with valid handles)
h = [tr(tracenum).handle];
h = h(find(ishandle(h)));
delete(h);
% delete references in trace struct and trace_list
n = setdiff(1:length(tr), tracenum);
tr = tr(n);
SetUIParam(me,'trace_axes','UserData',tr);
n = 1:length(tr);
SetUIParam(me,'trace_list','String', num2str(n'));
SetUIParam(me,'trace_list','Value', n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function saveData(filename, varargin)
% saves the analysis, either all traces [saveData(filename)]
% or specific traces [saveData(filename,tracenums)]
wait('Saving data...');
if nargin == 1
    data = getData;
    [pspdata, srdata, irdata, abstime] = getStats;
else
    data = getData(varargin{1});
    [pspdata, srdata, irdata, abstime] = getStats(varargin{1});
end
d = GetUIParam(me,'filename','UserData');
time = d.time;
info = d.info;
bf = GetUIParam(me,'bin_factor','StringVal');
if bf > 1
    info.binfactor = 1;
end
times = getTimes;

data = shiftdim(data,1);
pspdata = shiftdim(pspdata,1);
irdata = shiftdim(irdata,1);
abstime = shiftdim(abstime,1);
save(filename,'data','time','abstime','info','pspdata',...
    'srdata','irdata','times');
wait(['Data saved in ' filename]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function highlightTrace(trace)
% this function changes the trace's state from normal to highlighted
% in four places: the trace axes, the psp statistics, and the resistance stats
if isempty(trace)
    return;
end
currentcolor = get(trace,'Color');
if (strcmp(currentcolor,'red'))
    newcolor = 'black';
else
    newcolor = 'red';
end
set(trace,'Color',newcolor);
updateStats;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wait(varargin)
% changes pointer to an hourglass or back, depending on the pointer's state
% sets the status bar, if a string is supplied
if nargin > 0
    SetUIParam(me,'status','String',varargin{1});
end
p = getptr(gcf);
switch p{2}
case 'arrow'
    setptr(gcf,'watch');
otherwise
    setptr(gcf,'arrow');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function showSummary(pspdata,irdata,srdata,abstime)
% Computes time-weighted average and mean/stddev and displays them in the
% stats windows
SP = 0.1;

a = GetUIHandle(me,'psp_axes');
pspmean = mean(pspdata);
t = sprintf('Mean: %2.4f +/- %2.2f %%', pspmean, (std(pspdata) / pspmean * 100));
y = get(a, 'YLim');
x = get(a, 'XLim');
x = diff(x) * 0.80 + x(1);
text(x, diff(y) * 0.2 + y(1), t, 'Parent',a, 'Color', 'blue', 'FontWeight', 'bold');
[pspspline t] = TimeWeight(pspdata, abstime, SP,100);
plot(t, pspspline, 'b', 'Parent', a, 'Linewidth', 2)

a = GetUIHandle(me,'resist_axes');
srmean = mean(srdata);
irmean = mean(irdata);
t = sprintf('SR: %2.4f +/- %2.2f %%', srmean, (std(srdata) / srmean * 100));
y = get(a, 'YLim');
text(x, diff(y) * 0.2 + y(1), t, 'Parent', a, 'Color', 'blue', 'FontWeight', 'bold');
t = sprintf('IR: %2.4f +/- %2.2f %%', irmean, (std(irdata) / irmean * 100));
text(x, diff(y) * 0.8 + y(1), t, 'Parent', a, 'Color', 'red', 'FontWeight', 'bold');
[srspline t] = TimeWeight(srdata, abstime, SP, 100);
plot(t, srspline, 'b', 'Parent', a, 'Linewidth', 2);
[irspline t]= TimeWeight(irdata, abstime, SP, 100);
plot(t, irspline, 'r', 'Parent', a, 'Linewidth', 2);

