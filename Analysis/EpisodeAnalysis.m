function [] = EpisodeAnalysis()

% A specialized analysis application for use with episodic data, which often
% represents precisely timed repeats of a cellular response to stimulus presentation
% (for instance, extracellular stimuluation or visual flashes).  Episodes tend to
% be short in length, and the data that needs to be extracted is commonly the behavior
% of some variable over the course of the experiment.
%
% Previous incarnations of EpisodeAnalysis only supported three predefined parameters,
% the PSP (or PSC) amplitude (or slope), and the input and series resistance.  Because
% episodic acquisition is now being used for more complex stimuli, including multiple
% frames, this is a severe limitation, so the user is now allowed to select any number
% of parameters for analysis.
%
% This is implemented by creating a "window" of analysis that is typically 100-200 ms long
% over which some analysis function operates.  For instance, if the user is interested
% in the response to a single shock to the cortex, a single window can be specified for the
% PSP immediately following the stimulus artifact, and a "slope" function specified,
% which returns the slope of the response between two time offsets.
%
% The implementation of this is somewhat complicated because data has to be passed back
% and forth between the parameter figures and the main figure.  There is a single
% structure which accomplishes this, as it contains the handle of the parent figure and
% the child figures.  The child figure, which is managed by the EpisodeParameter mfile
% accesses the authoritative structure array which is stored in the appdata of the main
% figure.
%
% A second major change is designed to speed up the display of data.  Normally the user
% will be presented by an average trace, while analysis functions will operate on single
% sweeps.  The final results will be binned at whatever rate the user specifies.  Binning
% will only function over the final output of the analysis filters, reducing the amount of
% computation time used for displaying binned traces.
%
% Usage:  EpisodeAnalysis()  [all arguments are internal callbacks]
%
% To do: support multiple r0 files
%
% $Id$

error(nargchk(0,0,nargin))

initFigure;
initValues;

%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Figure specification:

function [] = initFigure()
% initialize the main figure window
cb = getCallbacks;
BG = [1 1 1];
f = OpenFigure(me,'position',[4 433 750 519],...
    'color',BG,'menubar','none');
movegui(f,'northwest')
set(f,'WindowButtonDownFcn',cb.clickaxes)
% Frame 0: File selection
h = uicontrol(gcf,'style','frame','backgroundcolor',BG,'position',[10 430 200 80]);
h = InitUIControl(me,'files','style','list',...
    'Callback',cb.pickfiles,'Max',2,...
    'position',[20 440 180 60],'backgroundcolor',BG);
% Frame 0.5: Trace information
h = uicontrol(gcf,'style','frame','backgroundcolor',BG,'position',[255 430 480 80]);
% Frame 1: Trace selection
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[10 155 200 270]);
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[25 395 160 20],...
    'Fontsize',10,'fontweight','bold','String','Traces');
h = InitUIControl(me, 'traces', 'style','list',...
    'Callback',cb.picktraces,'Max',2,...
    'position', [20 255 180 140],'backgroundcolor',BG);
h = InitUIControl(me, 'average', 'style', 'checkbox', 'backgroundcolor', BG,...
    'Callback',cb.selectaverage,'position',[20 235 180 20], 'String', 'Average Traces',...
    'Value', 1);
h = InitUIControl(me, 'channels', 'style', 'list',...
    'Callback',cb.pickchannels,'position', [20 165 180 70],'backgroundcolor',BG,'Max',2);
% Frame 2: Parameter selection
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[10 10 200 140]);
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[25 120 160 20],...
    'Fontsize',10,'fontweight','bold','String','Parameters');
m = uicontextmenu;
h = uimenu(m,'Label','Delete','Callback',cb.pickparams);
h = InitUIControl(me, 'parameters', 'style','list',...
    'Callback',cb.pickparams,'UIContextMenu',m,...
    'position', [20 30 180 90],'backgroundcolor',BG);
%h = InitUIControl(me, 'addparam', '
% Axes:
h = InitUIObject(me, 'response', 'axes', 'units','pixels','position',[255 60 480 360],...
    'nextplot','replacechildren','Box','On');
xlabel('Time (s)')
ylabel('Response')
% Status bar
h = InitUIControl(me, 'status', 'style', 'text', 'backgroundcolor', BG,...
    'position', [255 0 480 20],'String','(status)');
% Menus
file = uimenu(gcf, 'Label', '&File');
m    = uimenu(file, 'Label', '&Open Response...','Callback',cb.menu, 'tag', 'm_resp');
m    = uimenu(file, 'Label', 'Open &Parameters...','Callback',cb.menu,'tag','m_param');
m    = uimenu(file, 'Label', '&Save Parameters...', 'Callback', cb.menu,'tag','m_save');
m    = uimenu(file, 'Label', '&Export Results...', 'Callback', cb.menu,'tag','m_export');
m    = uimenu(file, 'Label', 'E&xit', 'Callback', cb.menu, 'Separator', 'On','tag','m_exit');

% par  = uimenu(gcf, 'Label', '&Parameters');
% m    = uimenu(par, 'Label', '

op   = uimenu(gcf,'Label','&Operations');
m    = uimenu(op, 'Label', 'Remove &Baseline', 'Callback', cb.menu, 'tag', 'm_baseline');
m    = uimenu(op, 'Label', '&Align Episodes', 'Callback', cb.menu, 'tag', 'm_align');
m    = uimenu(op, 'Label', 'Re&scale', 'Callback', cb.menu, 'tag', 'm_rescale');
m    = uimenu(op, 'Label', '&Crop', 'Callback', cb.menu, 'tag', 'm_crop');

% toolbar:

z   = load('gui_icons');
f   = {'ClickedCallback','ToolTip','CData','Tag'};

p   = cell2struct({cb.menu,'Open Response',z.opendoc,'m_resp'},f,2);
u   = InitUIObject(me,'m_resp','uipushtool',p);
p   = cell2struct({cb.menu,'Close Response',z.closedoc,'m_close'},f,2);
u   = InitUIObject(me,'m_close','uipushtool',p);
p   = cell2struct({cb.menu,'Export Response',z.savedoc,'m_export'},f,2);
u   = InitUIObject(me,'m_export','uipushtool',p);


p   = cell2struct({cb.menu,'Mouse Zoom',z.zoom,'mousezoom'},f,2);
u   = InitUIObject(me,'mousezoom','uitoggletool',p);
set(u,'Separator','On');
p   = cell2struct({cb.menu,'Reset Axes',z.fullview,'resetaxes'},f,2);
u   = InitUIObject(me,'resetaxes','uipushtool',p);
p   = cell2struct({cb.menu,'Select Parameter Window',z.mousezoom,'paramselect'},f,2);
u   = InitUIObject(me,'paramselect','uitoggletool',p);

p   = cell2struct({cb.menu,'Remove Baseline',z.zoominy,'m_baseline'},f,2);
u   = InitUIObject(me,'m_baseline','uipushtool',p);
set(u,'Separator','On');
p   = cell2struct({cb.menu,'Align Episodes',z.zoominx,'m_align'},f,2);
u   = InitUIObject(me,'m_baseline','uipushtool',p);
p   = cell2struct({cb.menu,'Rescale',z.zoomouty,'m_rescale'},f,2);
u   = InitUIObject(me,'m_rescale','uipushtool',p);

function [] = initValues()
% Initializes some app data so that calls to getappdata don't break
setappdata(gcf,'dir',pwd)       % current directory
setappdata(gcf,'r0',[])         % response file
setappdata(gcf,'parameters',[]) % parameter data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:

function [] = pickfiles(obj, event)
% this requires a call to updateDisplay
updateDisplay;

function [] = picktraces(obj, event)
plotTraces

function [] = selectaverage(obj, event)
plotTraces

function [] = pickchannels(obj,event)
plotTraces

function [] = pickparams(obj, event)
button = get(gcbf,'selectiontype');
switch lower(button)
case 'open'
    % re-open the parameter window
    v       = get(obj,'Value');
    p       = getappdata(gcbf,'parameters');
    p(v)    = EpisodeParameter('init',p(v));
    setappdata(gcbf,'parameters',p);
    updateParameters(p(v));
case 'alt'
    % right-click and selected delete
    obj     = findobj(gcbf,'tag','parameters');
    v       = get(obj,'Value');
    p       = getappdata(gcbf,'parameters');
    i       = setdiff(1:length(p),v);
    p       = p(i);
    setappdata(gcbf,'parameters',p);
    if ~isempty(p)
        set(obj,'String',{p.name},'Value',1);
    else
        set(obj,'String',{},'Value',1);
    end
end

function [] = clickaxes(obj, event)
% Handles rbbox operations in the axes; the action depends on the state of
% the mousezoom and paramselect uitoggletools.
% Selections in the axes have the effect of opening a new parameter with
% the window set to the x limits of the user's selection.  Right clicks and
% small windows have no effect
s1  = GetUIParam(me,'mousezoom','State');
s2  = GetUIParam(me,'paramselect','State');
if strcmpi(s1,'on')
    zoom(gcbf,'down')
elseif strcmpi(s2,'on')
    button = get(obj,'selectiontype');
    if strcmpi(button,'normal')
        ax  = get(obj, 'currentaxes');
        ini = get(ax,'CurrentPoint');
        x   = rbbox;
        fin = get(ax,'CurrentPoint');
        win = [ini(1),fin(1)];          % the window
        if diff(win) > 0.010
            createparameter(win)
        end
    end
end

function [] = menu(obj, event)
% handles menu callbacks
tag = get(obj, 'tag');
switch lower(tag)
case 'm_resp'
    % load responses (r0 files)
    path    = getappdata(gcf, 'dir');
    [fn pn] = uigetfile([path filesep '*.r0'],'Load Traces (r0)');
    if ~isnumeric(fn)
        [r0 str] = LoadResponseFile(fullfile(pn,fn));
        if isstruct(r0)
            storeData(r0, fn);
            updateDisplay;
        end
        setappdata(gcf,'dir',pn);
        SetUIparam(me,'status','String',str);
    end
case 'm_close'
    % close the currently selected responses (remove from list and backing store)
    v       = GetUIParam(me,'files','Value');
    c       = GetUIParam(me,'files','String');
    len     = length(c);
    switch len
    case 0
        return
    case 1
        c   = {};
        r   = [];
    otherwise
        ind = setdiff(len,v);
        r   = getappdata(gcf,'r0');
        c   = c(ind);
        r   = r(ind);
    end
    SetUIParam(me,'files','Value',1);
    SetUIParam(me,'files','String',c);
    setappdata(gcf,'r0',r);
    updateDisplay;
    
case 'm_save'
    % save parameters
    path    = getappdata(gcf,'dir');
    [fn pn] = uiputfile([path filesep '*.p0'],'Save Parameters (p0)');
    if ~isnumeric(fn)
        params = getappdata(gcf,'parameters');
        save(fullfile(pn,fn),'params','-mat');
        SetUIParam(me,'status','String',sprintf('Wrote %d parameters to %s',length(params),fn));
    end
case 'm_param'
    % load parameters
    path    = getappdata(gcf,'dir');
    [fn pn] = uigetfile([path filesep '*.p0'],'Load Parameters (p0)');
    if ~isnumeric(fn)
        d       = load('-mat',fullfile(pn,fn));
        if isfield(d,'params')
            % we have to delete all the existing parameters
            p  = getappdata(gcf,'parameters');
            if isstruct(p)
                h  = [p.handle];
                delete(h(find(ishandle(h))));
            end
            setappdata(gcf,'parameters',d.params);
            SetUIParam(me,'parameters','String',{d.params.name});
            SetUIParam(me,'status','String',sprintf('Loaded %d parameters from %s',...
                length(d.params),fn));
        else
            SetUIParam(me,'status','String','Unable to load parameters from file');
        end
    end
case 'm_export'
    % compute results of all parameters, then let the user save it in a .mat or .csv file
    p   = getappdata(gcf,'parameters');
    if length(p) == 0
        SetUIParam(me,'status','String','No parameters defined!');
        return
    end
    path    = getappdata(gcf,'dir');
    wd      = cd(path);
    [fn pn] = uiputfile({'*.mat';'*.csv'},'Save Results');
    cd(wd);
    if ~isnumeric(fn)
        r0  = getappdata(gcf,'r0');
        for i = 1:length(p)
            r            = windowR0(p(i).window,r0);
            p(i).results = EpisodeParameter('calc',p(i),r);
        end
    end
    [pn fi ext] = fileparts(fullfile(pn,fn));
    switch lower(ext)
    case '.mat'
        % store as a parameter structure array with data attached
        results = p;
        save(fullfile(pn,fn),'results')
    case '.csv'
        % store in columns. no easy way to provide column headers
        res = cat(1,p.results);
        d   = [r0.abstime' res'];
        csvwrite(fullfile(pn,fn),d);
    end
    SetUIParam(me,'status','String',sprintf('Wrote results to %s',fn));
        
case 'm_baseline'
    % adjust baseline (modifies stored r0), subtracting out DC of each trace
    r0      = getappdata(gcf,'r0');
    if isstruct(r0)
        for i = 1:length(r0)
            samp        = size(r0(i).data,1);
            m           = mean(r0(i).data,1);
            r0(i).data  = double(r0(i).data) - repmat(m,[samp,1,1]);
        end
        setappdata(gcf,'r0',r0);
        plotTraces;
        SetUIParam(me,'status','String','Baseline subtracted');
    end
case 'm_crop'
    % removes traces not selected in the trace list
    r0      = getappdata(gcf,'r0')
    if isstruct(r0)
        v   = GetUIParam(me,'traces','Value');
        r0.data     = r0.data(:,v,:);
        r0.abstime  = r0.abstime(v);
        setappdata(gcf,'r0',r0);
        updateDisplay;
        SetUIParam(me,'status','String','Episode cropped');
    end
case 'resetaxes'
    % resets axes limits
    a   = GetUIHandle(me,'response');
    axis(a,'tight');
case 'mousezoom'
    % the state of this button is queried by clickaxes(), but this mode is exclusive
    % with paramselect
    s  = get(obj,'State');
    if strcmpi(s,'on')
        h   = findobj(gcf,'tag','paramselect');
        if ~isempty(h)
            set(h,'State','Off')
        end
    end
case 'paramselect'
    s  = get(obj,'State');
    if strcmpi(s,'on')
        h   = findobj(gcf,'tag','mousezoom');
        if ~isempty(h)
            set(h,'State','Off')
        end
    end    
otherwise
    disp(tag)
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals:

function [] = createparameter(window)
% creates a new parameter defined over the time points supplied in the first
% argument.  The parameter is a structure which is stored in the "parameters"
% app data field.  An "EpisodeParameter" figure can be opened which displays
% the arguments of the analysis function and the results of the analysis.  If
% such a figure is open, the handle is stored in the "paramfigs" app data field,
% and an update command is sent to each open parameter figure when a new file is loaded
dt      = diff(window);
params  = getappdata(gcbf,'parameters');
p       = struct('window',window,'name','New Parameter','parent',gcbf,'type','none',...
                 'binning',1,'channel',GetUIParam(me,'channels','Value'),...
                 'marks',[dt * 0.3, dt * 0.7]);
p       = EpisodeParameter('init',p);       % structure includes handle of new figure
if isempty(params)
    params = p;
else
    params = cat(1,params,p);
end
names   = {params.name};
SetUIParam(me,'parameters','String',names);
setappdata(gcbf,'parameters',params);
updateParameters

function [] = storeData(r0, fn)
% Adds the r0 file to the data stored in the figure,
% adds filename to list
v   = GetUIParam(me,'files','String');
if iscell(v)
    v   = {v{:},fn};
elseif isempty(v)
    v   = {fn};
else
    v   = {v, fn};
end
SetUIParam(me,'files','String',v);
r   = getappdata(gcf,'r0');
if isempty(r)
    r   = r0;
else
    r   = cat(1,r,r0);
end
setappdata(gcf, 'r0', r);


function [] = updateDisplay()
% updates fields in the GUI with new data's properties
% this is kind of tricky.
r0  = getappdata(gcf, 'r0');
len = length(r0);
switch len
case 0
    % no data is loaded, so we need to clear everything
    SetUIParam(me,'traces','String',{});
    SetUIParam(me,'traces','Value',1);
    SetUIParam(me,'channels','String',{});
    SetUIParam(me,'channels','Value',1);
otherwise
    % now we have to check to see what the user has selected for display
    v   = GetUIParam(me,'files','Value');
    switch length(v)
    case 0
        % this shouldn't happen
        return
    case 1
        % when one file is selected, the user is allowed to pick multiple traces and
        % channels to display
        r0  = r0(v);
        [samp sweep chan] = size(r0.data);
        % update trace list
        tr = (1:sweep)';
        c  = cellstr(num2str(r0.abstime'));
        SetUIParam(me,'traces','String',c);
        SetUIParam(me,'traces','Value',tr);
        % update channel list
        if isfield(r0,'channels')
            c = {r0.channels.ChannelName};
        else
            c  = cellstr(num2str((1:chan)'));
        end
        SetUIParam(me,'channels','String',c);        
    otherwise
        % when multiple files are selected, we can either (a) only show average traces
        % (leaving the trace selection list blank) or (b) allow the user to color-code
        % traces from each file, and simply interleave the files' abstime values.  (a) is
        % easier to implement, but (b) may be useful at some point, and could be
        % switched to using the average trace clickbox
        SetUIParam(me,'traces','String',{'Multiple files selected'});
        SetUIParam(me,'traces','Value',1);
        SetUIParam(me,'channels','String',{'Multiple files selected'});
        SetUIParam(me,'channels','Value',1);
    end
end
% plot traces (or clear them if no data in r0 field)
plotTraces;
% update parameter windows with new data
updateParameters;

function [] = plotTraces()
% replots traces in the main window
r0  = getappdata(gcf,'r0');
if ~isempty(r0)
    % load and clear axes
    a   = GetUIHandle(me,'response');
    axes(a);
    cla
    hold on
    c   = cat(1,[0 0 0],get(a, 'ColorOrder'));
    % figure out what to plot:
    fls = GetUIParam(me,'files','Value');
    if length(fls) > 1
        % if multiple files selected, we plot the average of each r0
        for i = 1:length(fls)
            f      = fls(i);
            d      = mean(r0(f).data(:,:,1),2);
            p      = plot(r0(f).time, d);
            set(p,'Color',c(i,:))
        end
    else
        % one file selected, so we pick the traces and channels selected by the user
        r0  = r0(fls);
        tr  = GetUIParam(me,'traces','Value');
        chn = GetUIParam(me,'channels','Value');
        avg = GetUIParam(me,'average','Value');
        if avg == 0
            % plot unaveraged traces
            cd  = (c + 1) / 2;      % whitens the colors
            for i = 1:length(chn)
                p = plot(r0.time, r0.data(:,tr,chn(i)));
                set(p,'Color',cd(i,:),'LineWidth',0.1);
            end
        end
        % plot the averaged traces
        for i = 1:length(chn)
            d   = squeeze(mean(r0.data(:,tr,chn(i)),2));
            p   = plot(r0.time, d);
            set(p,'Color',c(i,:),'LineWidth',2);
        end
    end
end

function [] = updateParameters(p)
% calls the 'update' action on the parameter windows, which populates them
% with nice data
if nargin == 0
    p   = getappdata(gcbf,'parameters');
end
if ~isempty(p)
    r0  = getappdata(gcbf,'r0');
    for i = 1:length(p)
        h = p(i).handle;
        r = windowR0(p.window,r0);
        EpisodeParameter('update',h,r);
    end
end

function d = windowR0(window,r0)
% snips out the relevant bit of the r0 for each parameter
% what is returned is a 2D or 3D array containing the data points (time, sweep, channel)
% corresponding to the selected items in the main window
for j = 1:length(r0)
    r  = r0(j);
    t  = r.time >= window(1) & r.time <= window(2);   % logical array
    i  = find(t);                                           % indices
    r0(j).time = double(r.time(i));
    r0(j).data = double(r.data(i,:,:));
end

function out = me()
out = mfilename;

function out = getCallbacks()
% returns a structure with function handles to functions in this mfile
% no introspection in matlab so we have to do this by hand
fns = {'pickfiles','clickaxes','picktraces','pickchannels','selectaverage','pickparams','menu'};
out = [];
for i = 1:length(fns)
    sf = sprintf('out.%s = @%s;',fns{i},fns{i});
    eval(sf);
end