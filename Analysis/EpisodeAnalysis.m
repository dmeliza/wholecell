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
set(f,'WindowButtonDownFcn',cb.clickaxes,'KeyPressFcn',cb.keypress)
% Frame 0: File selection
h = uicontrol(gcf,'style','frame','backgroundcolor',BG,'position',[10 430 200 80]);
h = InitUIControl(me,'files','style','list',...
    'Callback',cb.pickfiles,'Max',2,...
    'position',[20 440 180 60],'backgroundcolor',BG);
% Frame 0.5: Trace information
% h = uicontrol(gcf,'style','frame','backgroundcolor',BG,'position',[255 430 480 80]);
% Frame 1: Trace selection
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[10 155 200 270]);
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[25 395 160 20],...
    'Fontsize',10,'fontweight','bold','String','Traces');
h = InitUIControl(me, 'traces', 'style','list',...
    'Callback',cb.picktraces,'Max',2,...
    'position', [20 255 180 140],'backgroundcolor',BG);
h = InitUIControl(me, 'average', 'style', 'checkbox', 'backgroundcolor', BG,...
    'Callback',cb.selectaverage,'position',[20 235 100 20], 'String', 'Average Traces',...
    'Value', 1);
h = InitUIControl(me, 'labels', 'style', 'checkbox', 'backgroundcolor', BG,...
    'Callback',cb.selectlabel,'position',[140 235 60 20], 'String', 'Labels',...
    'Value', 0);
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
    'position', [20 80 180 40],'backgroundcolor',BG);
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[20 50 40 20],...
    'horizontalalignment','left','String','Name:');
h = InitUIControl(me,'parametername','style','edit','Callback',cb.editparameter,...
    'position', [100 55 100 20],'backgroundcolor',BG,'horizontalalignment','right',...
    'enable','off');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[20 30 40 20],...
    'horizontalalignment','left','String','Action:');
t = {'none','amplitude','difference','slope'};
h = InitUIControl(me,'parameteraction','style','popup','Callback',cb.editparameter,...
    'position', [100 35 100 20],'backgroundcolor',BG,'String',t,'enable','off');
%h = InitUIControl(me, '
% Trace Axes:
h = InitUIObject(me, 'response', 'axes', 'units','pixels','position',[255 190 480 310],...
    'nextplot','replacechildren','Box','On');
xlabel('Time (s)')
ylabel('Response')
% Parameter axes:
h = InitUIObject(me, 'timecourse','axes','units','pixels','position',[255 60 480 90],...
     'nextplot','replacechildren','Box','On');
xlabel('Time (m)')
% Status bar
h = InitUIControl(me, 'status', 'style', 'text', 'backgroundcolor', BG,...
    'position', [255 0 480 20],'String','(status)');
% Menus
file = uimenu(gcf, 'Label', '&File');
m    = uimenu(file, 'Label', '&Open Response...','Callback',cb.menu, 'tag', 'm_resp');
m    = uimenu(file, 'Label', 'Open &Parameters...','Callback',cb.menu,'tag','m_param');
m    = uimenu(file, 'Label', 'Save &Response...','Callback',cb.menu,'tag','m_saveresp');
m    = uimenu(file, 'Label', 'Save &Traces...','Callback',cb.menu,'tag','m_savetrace');
m    = uimenu(file, 'Label', '&Save Parameters...', 'Callback', cb.menu,'tag','m_save');
m    = uimenu(file, 'Label', '&Export Results...', 'Callback', cb.menu,'tag','m_export');
m    = uimenu(file, 'Label', 'E&xit', 'Callback', cb.menu, 'Separator', 'On','tag','m_exit');

op   = uimenu(gcf,'Label','&Operations');
m    = uimenu(op, 'Label', 'Remove &Baseline', 'Callback', cb.menu, 'tag', 'm_baseline');
m    = uimenu(op, 'Label', '&Align Episodes', 'Callback', cb.menu, 'tag', 'm_align');
m    = uimenu(op, 'Label', 'Re&scale...', 'Callback', cb.menu, 'tag', 'm_rescale');
m    = uimenu(op, 'Label', '&Crop', 'Callback', cb.menu, 'tag', 'm_crop');
m    = uimenu(op, 'Label', '&Delete', 'Callback', cb.menu, 'tag', 'm_delete');
m    = uimenu(op, 'Label', '&Filter...', 'Callback', cb.menu, 'tag', 'm_filter');
m    = uimenu(op, 'Label', '&Trace Properties...', 'Callback', cb.menu, 'tag', 'm_traceprop');

% toolbar:

z   = load('gui_icons');
f   = {'ClickedCallback','ToolTip','CData','Tag'};

p   = cell2struct({cb.menu,'Open Response',z.opendoc,'m_resp'},f,2);
u   = InitUIObject(me,'m_resp','uipushtool',p);
p   = cell2struct({cb.menu,'Close Response',z.closedoc,'m_close'},f,2);
u   = InitUIObject(me,'m_close','uipushtool',p);
p   = cell2struct({cb.menu,'Export Response',z.savedoc,'m_export'},f,2);
u   = InitUIObject(me,'m_export','uipushtool',p);

p   = cell2struct({cb.menu,'Move Object',z.select,'moveobject'},f,2);
u   = InitUIObject(me,'moveobject','uitoggletool',p);
set(u,'Separator','On','State','On');
p   = cell2struct({cb.menu,'Mouse Zoom',z.zoom,'mousezoom'},f,2);
u   = InitUIObject(me,'mousezoom','uitoggletool',p);
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
p   = cell2struct({cb.menu,'Filter Traces',z.arraysigs,'m_filter'},f,2);
u   = InitUIObject(me,'m_filter','uipushtool',p);
p   = cell2struct({cb.menu,'Trace Properties',z.lineprop,'m_traceprop'},f,2);
u   = InitUIObject(me,'m_traceprop','uipushtool',p);

p   = cell2struct({cb.menu,'Toggle Parameter Display',z.markers,'m_showparams'},f,2);
u   = InitUIObject(me,'m_showparams','uitoggletool',p);
set(u,'Separator','On','State','On');

function [] = initValues()
% Initializes some app data so that calls to getappdata don't break
setappdata(gcf,'dir',pwd)       % current directory
setappdata(gcf,'r0',[])         % response file
setappdata(gcf,'parameters',[]) % parameter data
setappdata(gcf,'param_handles',[])
setappdata(gcf,'param_mark_handles',[]);
setappdata(gcf,'ds',[]);        % dataselector

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:

function [] = pickfiles(obj, event)
% this requires a call to updateDisplay
updateFields
plotTraces

function [] = picktraces(obj, event)
updateDS
plotTraces

function [] = selectaverage(obj, event)
plotTraces

function [] = selectlabel(obj, event)
plotTraces

function [] = pickchannels(obj,event)
updateDS
plotTraces

function [] = pickparams(obj,event)
button = get(gcbf,'selectiontype');
switch lower(button)
case 'normal'
    updateParameters
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
    updateParameters
end

function [] = editparameter(obj, event)
% updates the parameter appdata with values in fields
params  = getappdata(gcf,'parameters');
if isempty(params)
    return
end
name    = GetUIParam(me,'parametername','String');
c       = GetUIParam(me,'parameteraction','String');
v       = GetUIParam(me,'parameteraction','Value');
action  = c{v};
names   = GetUIParam(me,'parameters','String');
ind     = GetUIParam(me,'parameters','Value');
params(ind).name = name;
params(ind).action = action;
names{ind} = name;
setappdata(gcf,'parameters',params);
SetUIParam(me,'parameters','String',names);
plotParameter

function [] = keypress(obj, event)
% handles keypress activity.  I want to capture ctrl-a and maybe some other things
key = get(obj,'currentkey');
mod = get(obj,'currentmodifier');
if isempty(key)
    return
end
switch key
case 'a'
    if strcmpi(mod{1},'control')
        c   = GetUIParam(me,'traces','String');
        SetUIParam(me,'traces','Value',1:length(c));
        picktraces([],[])
    end
case 'downarrow'
    ui = get(obj, 'CurrentObject');
    if strcmpi(get(ui,'tag'),'traces')
        v = get(ui,'Value');
        c = length(get(ui,'String'));
        v = (v + 1);
        v = unique((v <= c) .* v + (v > c) .* c);
        set(ui,'Value',v)
        updateDS,plotTraces
    end
case 'uparrow'
    ui = get(obj, 'CurrentObject');
    if strcmpi(get(ui,'tag'),'traces')
        v = get(ui,'Value');
        c = get(ui,'String');
        v = (v - 1);
        v = unique((v > 0) .* v + (v < 1) .* 1);
        set(ui,'Value',v)
        updateDS,plotTraces
    end
end

function [] = clickaxes(obj, event)
% Handles rbbox operations in the axes; the action depends on the state of
% the mousezoom and paramselect uitoggletools.
% Selections in the axes have the effect of opening a new parameter with
% the window set to the x limits of the user's selection.  Right clicks and
% small windows have no effect
s0  = GetUIParam(me,'moveobject','State');
s1  = GetUIParam(me,'mousezoom','State');
s2  = GetUIParam(me,'paramselect','State');
if strcmpi(s1,'on')
    zoom(gcbf,'down')
elseif strcmpi(s0,'on')
    o   = get(obj,'CurrentObject');
    t   = get(o,'Tag');
    if strcmpi(t,'mark')
        dragHandler = @dragMark;
        releaseHandler = @releaseMark;
        set(obj,'WindowButtonMotionFcn',dragHandler);
        set(obj,'WindowButtonUpFcn',releaseHandler);
    end
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% these functions define a drag operation; we have to do some fancy callback
% magic
function dragMark(obj, event)
h   = get(gcf,'CurrentObject');
pt  = get(gca,'CurrentPoint');
x   = pt(1);
set(h,'XData',[x x]);

function releaseMark(obj, event)
set(gcf,'WindowButtonMotionFcn','');
set(gcf,'WindowButtonUpFcn','');
h   = get(gcf,'CurrentObject');
mh  = getappdata(gcf,'param_handles');
ind = find(mh==h);
if ~isempty(ind)
    p       = getappdata(gcf,'parameters');
    v       = GetUIParam(me,'parameters','Value');
    x       = get(h,'XData');
    p(v).marks(ind) = x(1);
    setappdata(gcf,'parameters',p);
    plotParameter(p(v));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
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
            updateFields;
            plotTraces;
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
        ds  = [];
    otherwise
        ind = setdiff(1:len,v);
        r   = getappdata(gcf,'r0');
        ds  = getappdata(gcf,'ds');
        c   = c(ind);
        r   = r(ind);
        ds  = ds(ind);
    end
    SetUIParam(me,'files','Value',1);
    SetUIParam(me,'files','String',c);
    setappdata(gcf,'r0',r);
    setappdata(gcf,'ds',ds);
    updateFields;
    plotTraces
    
case 'm_saveresp'
    % saves the currently selected file in a new r0 file
    % only works with one file selected (for now)
    fls     = GetUIParam(me,'files','Value');
    if length(fls) == 1
        path    = getappdata(gcf,'dir');
        [fn pn] = uiputfile([path filesep '*.r0'],'Save Response (r0)');
        if ~isnumeric(fn)
            r0  = getappdata(gcf,'r0');
            r0  = r0(fls);
            save(fullfile(pn,fn),'r0','-mat')
            SetUIParam(me,'status','String',['Wrote response to ' fn]);
        end
    else
        SetUIParam(me,'status','String','Only single files can be saved')
    end
    
case 'm_savetrace'
    % saves the data in the trace window in a matfile
    % only operates on average traces and the first selected channel
    % granted, this is not flexible, but screw you flexible-man
    path    = getappdata(gcf,'dir');
    [fn pn] = uiputfile([path filesep '*.mat'],'Save Traces (mat)');
    if isnumeric(fn)
        return
    end
    ds      = getSelected;
    fname   = {};
    for i = 1:length(ds)
        fname{i}    = ds(i).fn;
        data(:,i)   = mean(ds(i).data(:,:,1),2);
    end
    time            = ds(end).time;
    save(fullfile(pn,fn),'fname','data','time')
    SetUIParam(me,'status','String',['Traces saved to ' fn]);
    
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
            setappdata(gcf,'parameters',d.params);
            SetUIParam(me,'parameters','String',{d.params.name});
            updateParameters
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
    % operates on all traces and signals in the selected files
    r0      = getappdata(gcf,'r0');
    fls     = GetUIParam(me,'files','Value');
    if isstruct(r0)
        for i = 1:length(fls)
            f           = fls(i);
            samp        = size(r0(f).data,1);
            m           = mean(r0(f).data,1);
            r0(f).data  = double(r0(f).data) - repmat(m,[samp,1,1]);
        end
        setappdata(gcf,'r0',r0);
        plotTraces
        SetUIParam(me,'status','String','Baseline subtracted');
    end
case 'm_crop'
    % removes traces not selected in the trace list
    % only works if a single file is selected
    % TODO: add a tool for cropping multiple files
    fls     = GetUIParam(me,'files','Value');
    if length(fls) == 1
        r0      = getappdata(gcf,'r0');
        if isstruct(r0)
            v       = GetUIParam(me,'traces','Value');
            ds      = getappdata(gcf,'ds');
            r0(fls).data     = r0(fls).data(:,v,:);
            at               = r0(fls).abstime(v)';
            r0(fls).abstime  = at;
            ds(fls).abstime  = at;
            ds(fls).sweeps   = (1:length(at))';
            setappdata(gcf,'r0',r0);
            setappdata(gcf,'ds',ds);
            updateFields;
            plotTraces
            SetUIParam(me,'status','String','Episode cropped');
        end
    end
case 'm_delete'
    % removes selected traces
    % only works if a single file is selected
    % TODO: add a tool for cropping multiple files
    fls     = GetUIParam(me,'files','Value');
    if length(fls) == 1
        r0      = getappdata(gcf,'r0');
        if isstruct(r0)
            sel       = GetUIParam(me,'traces','Value');
            ds        = getappdata(gcf,'ds');
            v         = setdiff(1:length(ds(fls).abstime),sel)';
            r0(fls).data     = r0(fls).data(:,v,:);
            at               = r0(fls).abstime(v)';
            r0(fls).abstime  = at;
            ds(fls).abstime  = at;
            ds(fls).sweeps   = (1:length(at))';
            setappdata(gcf,'r0',r0);
            setappdata(gcf,'ds',ds);
            updateFields;
            plotTraces
            SetUIParam(me,'status','String','Episode cropped');
        end
    end   
case 'resetaxes'
    % resets axes limits
    a   = GetUIHandle(me,'response');
    mh  = getappdata(gcf,'param_handles');
    set(mh(ishandle(mh)),'handlevisibility','off','visible','off');
    set(a,'xlimmode','auto','ylimmode','auto')
    set(mh(ishandle(mh)),'handlevisibility','callback','visible','on');
    zoom reset;
case {'mousezoom','paramselect','moveobject'}
    % the state of this button is queried by clickaxes(), but this mode is exclusive
    % with paramselect
    ts  = {'mousezoom','paramselect','moveobject'};
    s   = get(obj,'State');
    t   = get(obj,'Tag');
    if strcmpi(s,'on')
        i   = strmatch(t,ts);
        ind = setdiff(1:length(ts),i);
        for i = 1:length(ind)
            h   = findobj(gcf,'tag',ts{ind(i)});
            if ~isempty(h)
                set(h,'State','Off')
            end
        end
    end
case 'm_filter'
    % pops up a window asking for the cutoff and order of the filter
    % we run all the selected files through a butterworth
    a   = inputdlg({'Filter cutoff', 'Filter order'},'Filter Parameters',1,{'1000','3'});
    if isempty(a)
        return
    end
    lp  = str2num(a{1});
    od  = str2num(a{2});
    r0  = getappdata(gcf,'r0');
    fls = GetUIParam(me,'files','Value');
    for i = 1:length(fls)
        f       = fls(i);
        Fs      = r0(f).t_rate / 2; % max sampling rate
        if lp < Fs
            [b a]   = butter(od,lp/Fs);
            r0(f).data = filtfilt(b, a, double(r0(f).data));
        end
    end
    setappdata(gcf,'r0',r0)
    plotTraces
    
case 'm_traceprop'
    % user can pick a new color for the selected traces
    f  = GetUIParam(me,'files','Value');
    ds = getappdata(gcf,'ds');
    if ~isempty(ds)
        col  = cat(1,ds(f).color);
        newc = uisetcolor(col(1,:),'Set Trace Color');
        % no way to tell if the user has hit cancel...
        for i = 1:length(f)
            c   = ds(f(i)).chan;
            [ds(f(i)).color(c,:)] = repmat(newc,length(c),1);
        end
        setappdata(gcf,'ds',ds);
        plotTraces
    end
    
case 'm_showparams'
    updateParameters
            
otherwise
    disp(tag)
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals:

function ds = getDataSelector(r0)
% returns a structure that defines the set of data the user wishes to view.
%   .start  - the absolute time at which the data starts
%   .abstime - the offsets (in minutes) from the start time of each sweep
%   .sweeps - an array of indices defining which sweeps to use
%   .channels - a cell structure of the channel names
%   .chan   - an array of indices defining which channels to use
%   .color  - an Nx3 array defining the color to use for each channel (random from hsv)
cnum = size(r0.data,3);
if isfield(r0,'channels')
    c = {r0.channels.ChannelName};
else
    c  = cellstr(num2str((1:cnum)'));
end
cmap  = jet(50);
cmap  = cmap(randperm(50),:);
at    = r0.abstime(:); % convert to column vector
ds = struct('start',r0.info.start_time,'abstime',at,...
            'sweeps',(1:length(r0.abstime))','channels',{c},...
            'chan',1,'color',cmap(1:cnum,:));

function [] = createparameter(window)
% creates a new parameter defined over the time points supplied in the first
% argument.  The parameter is a structure which is stored in the "parameters"
% app data field.
dt      = diff(window);
params  = getappdata(gcbf,'parameters');
p       = struct('marks',window,'name','New Parameter','action','none',...
                 'binning',1,'channel',GetUIParam(me,'channels','Value'));%,...
%                 'marks',[dt * 0.3, dt * 0.7]);
if isempty(params)
    params = p;
else
    params = cat(1,params,p);
end
names   = {params.name};
SetUIParam(me,'parameters','String',names);
SetUIParam(me,'parameters','Value',length(names));
setappdata(gcbf,'parameters',params);
updateParameters

function [] = storeData(r0, fn)
% Adds the r0 file to the data stored in the figure,
% adds filename to list and initializes default values of dataselector
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
ds  = getappdata(gcf,'ds');
d_new = getDataSelector(r0);
if isempty(r)
    r   = r0;
    ds  = d_new;
else
    r   = cat(1,r,r0);
    ds  = cat(1,ds,d_new);
end
setappdata(gcf, 'r0', r);
setappdata(gcf, 'ds', ds);


function [] = updateFields()
% updates fields in the GUI according to the files selected by the user
ds  = getappdata(gcf, 'ds');
switch length(ds)
case 0
    % no data is loaded, so we need to clear everything
    SetUIParam(me,'traces','String',{});
    SetUIParam(me,'traces','Value',1);
    SetUIParam(me,'channels','String',{});
    SetUIParam(me,'channels','Value',1);
otherwise
    % based on the number of files selected, load values into the fields
    v   = GetUIParam(me,'files','Value');
    switch length(v)
    case 0
        % this shouldn't happen
        return
    case 1
        % when one file is selected, the user is allowed to pick multiple traces and
        % channels to display.  Changes are updated in the 'ds' appdata, which means
        % they persist even if the user changes which file he wants to view
        ds  = ds(v);
        SetUIParam(me,'traces','String',cellstr(num2str(ds.abstime)));
        SetUIParam(me,'traces','Value',ds.sweeps);
        SetUIParam(me,'channels','String',ds.channels);
        SetUIParam(me,'channels','Value',ds.chan);
    otherwise
        % when multiple files are selected, the user is not allowed to select individual
        % traces or channels; rather, these values are obtained from the ds appdata
        SetUIParam(me,'traces','String',{'Multiple files selected'});
        SetUIParam(me,'traces','Value',1);
        SetUIParam(me,'channels','String',{'Multiple files selected'});
        SetUIParam(me,'channels','Value',1);
    end    
end

function [] = updateDS()
% updates the dataselector ('ds') appdata based on what the user has selected
% in the GUI fields
d   = getappdata(gcf,'ds');
if length(d) == 0
    return
end
v   = GetUIParam(me,'files','Value');
switch length(v)
case 1
    tr  = GetUIParam(me,'traces','Value');
    chn = GetUIParam(me,'channels','Value');
    d(v).sweeps = tr;
    d(v).chan   = chn;
    setappdata(gcf,'ds',d);
otherwise
    % actions ignored if multiple files are selected
end

function ds = getSelected()
% returns the "active" dataset
ds  = getappdata(gcf,'ds');
if length(ds) == 0
    return
end
fls = GetUIParam(me,'files','Value');
fn  = GetUIParam(me,'files','String');
r0  = getappdata(gcf,'r0');
ds  = ds(fls);
for i = 1:length(fls)
    f               = fls(i);
    ds(i).fn        = fn{f};
    ds(i).data      = r0(f).data(:,ds(i).sweeps,ds(i).chan);
    ds(i).abstime   = r0(f).abstime(ds(i).sweeps);
    ds(i).time      = r0(f).time;
    ds(i).units     = r0(f).y_unit;
end

function [] = plotTraces()
% replots traces in the main window
ds  = getSelected;
a   = GetUIHandle(me,'response');
axes(a),cla,hold on
lbl = GetUIParam(me,'labels','Value');
ct  = 0;
for i = 1:length(ds)
    avg = GetUIParam(me,'average','Value');
    for j = 1:size(ds(i).data,3)
        c   = ds(i).color(ds(i).chan(j),:);
        if ~avg
            pi   = plot(ds(i).time,ds(i).data(:,:,j));
            cd  = (c + 1) / 2;
            set(pi,'Color',cd);
        end
        ct      = ct+1;
        m       = mean(ds(i).data(:,:,j),2);
        p(ct)   = plot(ds(i).time, m);
        set(p(ct),'Color',c,'LineWidth',2);
        if lbl
            if length(ds(i).sweeps) > 1
                ats = sprintf('%3.1f - %3.1f', ds(i).abstime(1), ds(i).abstime(end));
            else
                ats = sprintf('%3.1f', ds(i).abstime(1));
            end
            str{ct} = sprintf('%s:%s(%s) %s ', ds(i).fn, ds(i).channels{ds(i).chan(j)},...
                      ds.units, ats);
        end
    end
end
if ~isempty(ds)
    plotParameter
    if lbl
        h = legend(p,str{:});
    end
end

function [] = updateParameters()
% Updates display when a new parameter is selected or created
p   = getappdata(gcbf,'parameters');
v   = GetUIParam(me,'parameters','Value');
if ~isempty(p)
    SetUIParam(me,'parametername','String',p(v).name);
    SetUIParam(me,'parametername','Enable','On');
    c   = GetUIParam(me,'parameteraction','String');
    i   = strmatch(p(v).action,c);
    if isempty(i)
        i = 1;
    end
    SetUIParam(me,'parameteraction','Value',i);
    SetUIParam(me,'parameteraction','Enable','On');
    plotMarks(p(v).marks);

    % calculate things
    plotParameter(p(v));
else
    mh  = getappdata(gcf,'param_handles');
    delete(mh(ishandle(mh)));
    SetUIParam(me,'parametername','Enable','Off');
    SetUIParam(me,'parameteraction','Enable','Off');
end

function [] = plotMarks(marks)
% clear marks, draw marks
mh  = getappdata(gcbf,'param_handles');
delete(mh(ishandle(mh)));
st  = GetUIParam(me,'m_showparams','State');
if strcmpi(st,'on')
    axes(GetUIHandle(me,'response'))
    mh = vline(marks,{'k','k:'});
    set(mh,'tag','mark','handlevisibility','callback');
    setappdata(gcbf,'param_handles',mh);
end

function [] = plotParameter(param)
% plots a parameter's time course on the parameter axes
ax  = GetUIHandle(me,'timecourse');
axes(ax)
cla,hold on
st  = GetUIParam(me,'m_showparams','State');
if strcmpi(st,'off')
    return
elseif nargin < 1
    param = getappdata(gcf,'parameters');
    if isempty(param)
        return
    end
    v     = GetUIParam(me,'parameters','Value');
    param = param(v);
end
ds  = getSelected;
if ~isempty(ds)
    res = EpisodeParameter(param, ds);
    ax  = GetUIHandle(me,'timecourse');
    axes(ax)
    cla,hold on
    for i = 1:length(res)
        p      = scatter(res(i).abstime, res(i).value, 10, res(i).color);
        m      = mean(res(i).value);
        h(i)   = line([res(i).abstime(1) res(i).abstime(end)],[m m]);
        set(h(i),'Color',res(i).color,'LineStyle',':')
        str{i} = sprintf('%3.2f %s', m, res(i).units);
    end
    lbl = GetUIParam(me,'labels','Value');
    if lbl
        legend(h,str);
    end
end 

function out = me()
out = mfilename;

function out = getCallbacks()
% returns a structure with function handles to functions in this mfile
% no introspection in matlab so we have to do this by hand
fns = {'pickfiles','clickaxes','picktraces','pickchannels',...
        'editparameter','selectaverage','pickparams','menu','keypress','selectlabel'};
out = [];
for i = 1:length(fns)
    sf = sprintf('out.%s = @%s;',fns{i},fns{i});
    eval(sf);
end

