function out = EpisodeParameter(varargin)
%
% An internal function used to display the time course and statistics
% of some measured parameter in an episodic acquisition (e.g. input resistance)
%
% Usage:
%
%       p = EpisodeParameter('init',paramstruct)        
%           - opens the figure, returns an updated parameter structure
%       EpisodeParameter('update',h,data,time,abstime)               
%           - updates the data in the figure (h is the handle of the figure)
%
% This function is responsible for maintaining the parameter's representation
% in the main figure's appdata.  That way, when the figure is closed, the
% main figure will still contain the data necessary to reopen the figure.
%
% $Id$

switch nargin
case {0,1}
    disp('EpisodeParameter is started from EpisodeAnalysis')
    return
case 2
    action  = varargin{1};
    p       = varargin{2};
    p       = initFigure(p);
    out     = p;
case 5
    d       = cell2struct(varargin(3:5),{'data','time','abstime'},2);
    updateFigure(varargin{2},d);
otherwise
    disp('Check usage...')
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = updateFigure(f, d)
% plots the data
if nargin == 1
    d    = getappdata(f, 'data');
else
    setappdata(f,'data',d);
end
% axis 1
a   = findobj(f,'tag','trace');
if ishandle(a)
    h   = findobj(f,'tag','channel');
    c = str2num(get(h,'String'));
    axes(a)
    cla
    hold on
    p = plot(d.time,d.data(:,:,c));
    set(p,'color',[0.6 0.6 0.6])
    p = plot(d.time,mean(d.data(:,:,c),2));
    set(p,'linewidth',2)
    axis(a,'tight')
end
h   = findobj(f,'tag','type');
v   = get(h,'value');
s   = get(h,'string');
s   = lower(s{v});
switch s
case 'none'
    % do nothing
case 'amplitude'
    % absolute value of the amplitude difference between two marks
    m   = getMarks(a,s);
case 'slope'
end

function m = getMarks(ax,type)
% returns the location of the marks on the trace, or if the marks are not to be found,
% creates them.  The values in the 'marks' appdata are authoritative.
f   = get(ax,'parent');
% if marks exist in the parameter structure:
if isappdata(f,'marks')
    m  = getappdata(f,'marks');
    mh = findobj(f,'tag','mark');
    if isempty(mh)
        % if no lines have been drawn, draw them
        mh = plotMarks(ax,m);
    end
end


function mh = plotMarks(ax, m)
% plots lines at various x locations (marks)
% marks are defined as the offset (in seconds) from the first point of the graph
ls  = {'-','--',':'};
yp  = 70;
d   = 25;

f       = get(ax,'parent');
wh      = findobj(f,'tag','window');
w       = str2num(get(wh,'String'));
y       = get(ax,'YLim');
axes(ax)
hold on
for i = 1:length(m);
    x       = w(1) + m(i);
    h       = uicontrol(f,'style','text','backgroundcolor',[1 1 1],...
                        'position',[15 yp 40 20],'String',sprintf('Mark %d', i));
    h       = uicontrol(f,'style','edit','backgroundcolor',[1 1 1],...
                        'enable','inactive','tag',sprintf('mark%d', i),...
                        'position',[60 yp 95 18],'String',num2str(x));    
    mh(i)   = line([x x],y,'Color',[0 0 0],'LineStyle',ls{i},'tag','mark',...
                   'UserData',h);

    yp      = yp - d;
end
        

function p = initFigure(p)
% Note that because multiple figures may be open, we can't use the usual
% UI functions to access objects.
t   = {'none','amplitude','slope'};
cb  = @editField;
cbb = @cleanup;
cf  = @clickfcn;
BG  = [1 1 1];
f   = figure('tag','episodeparameter','name','episodeparameter',...
    'position',[50   343   950   220],...
    'color',BG,'menubar','none','CloseRequestFcn',cbb,'WindowButtonDownFcn',cf);
p.handle = f;
setappdata(f,'parent',p.parent);
% Frame - parameters for analysis
h   = uicontrol(f,'style','frame','backgroundcolor',BG,'position',[10 10 150 200]);

h   = uicontrol(f,'style','text','String','Window','backgroundcolor',BG,...
    'position',[15 180 40 20],'horizontalalignment','left');
h   = uicontrol(f,'style','edit','backgroundcolor',BG,'tag','window','callback',cb,...
    'position',[60 185 95 18],'horizontalalignment','right','Enable','inactive',...
    'String',sprintf('[%3.3f  %3.3f]',p.window));

h   = uicontrol(f,'style','text','String','Name','backgroundcolor',BG,...
    'position',[15 155 40 20],'horizontalalignment','left');
h   = uicontrol(f,'style','edit','backgroundcolor',BG,'tag','name','callback',cb,...
    'position',[60 160 95 18],'horizontalalignment','right','String',p.name);

h   = uicontrol(f,'style','text','String','Type','backgroundcolor',BG,...
    'position',[15 130 35 20],'horizontalalignment','left');
h   = uicontrol(f,'style','popup','backgroundcolor',BG,'tag','type','callback',cb,...
    'position',[60 135 95 18],'String',t);
i   = strmatch(p.type,t,'exact');
if ~isempty(i)
    set(h,'Value',i);
end

% h   = uicontrol(f,'style','text','String','Binning:','backgroundcolor',BG,...
%     'position',[15 96 40 20],'horizontalalignment','left');
% h   = uicontrol(f,'style','edit','backgroundcolor',BG,'tag','binning','callback',cb,...
%     'position',[15 80 140 18],'horizontalalignment','right','String',num2str(p.binning));

h   = uicontrol(f,'style','text','String','Channel:','backgroundcolor',BG,...
    'position',[15 105 40 20],'horizontalalignment','left');
h   = uicontrol(f,'style','edit','backgroundcolor',BG,'tag','channel','callback',cb,...
    'position',[60 110 95 18],'horizontalalignment','right','String',num2str(p.channel));

% Axes 1: Mean trace
a1   = axes;
set(a1,'units','pixels','position',[180 20 150 180],'box','on','ytick',[],'tag','trace');
% Axes 2: Time-course
a2   = axes;
set(a2,'units','pixels','position',[370 40 350 150],'box','on','tag','timecourse');
% Axes 3: Histogram
a3   = axes;
set(a3,'units','pixels','position',[750 20 180 180],'box','on','ytick',[],'tag','histogram');
set([a1 a2 a3],'nextplot','replacechildren');
%zoom on;
% store mark data if supplied
if isfield(p,'marks')
    setappdata(f,'marks',p.marks)
end

function [] = editField(obj, event)
% handles what happens when the user edits a field
par     = getappdata(gcbf,'parent');
parms   = getappdata(par,'parameters');
h       = [parms.handle];
i       = find(h==gcbf);     % if this is empty, figure is not linked
if ~isempty(i)
    t   = get(obj,'tag');
    if strcmpi(t,'mark')
        wh  = findobj(gcbf,'tag','window');
        w   = str2num(get(wh,'String'));
        mh  = findobj(gcbf,'tag','mark');
        for j = 1:length(mh)
            x    = get(mh(j),'xdata');
            m(j) = x(1) - w(1);
        end
        m = fliplr(m);  % for some reason the order of the marks gets reversed by findobj
        setappdata(gcbf,'marks',m);
        parms(i).marks = m;
    else
        s   = get(obj,'String');
        switch lower(t)
        case 'name'
            parms(i).name = s;
        case 'type'
            v = get(obj,'Value');
            parms(i).type = s{v};
        case 'binning'
            parms(i).binning = str2num(s);
        case 'channel'
            parms(i).channel = str2num(s);
        end
        setappdata(par,'parameters',parms);
        t = findobj(par,'tag','parameters');
        set(t,'String',{parms.name});
    end
    updateFigure(gcbf)
end

function [] = clickfcn(obj, event)
% handles buttondown actions for the whole figure
h       = get(obj,'currentobject');
switch lower(get(h,'type'))
case 'axes'
    zoom(gcbf,'down');
case 'line'
    if strcmpi(get(h,'tag'),'mark')
        set(gcf,'doublebuffer','on');
        dragHandler = @dragMark;
        releaseHandler = @releaseMark;
        set(obj,'WindowButtonMotionFcn',dragHandler);
        set(obj,'WindowButtonUpFcn',releaseHandler);
    else
        zoom(gcbf,'down');
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
eh  = get(h,'UserData');
set(eh,'String',num2str(x));

function releaseMark(obj, event)
set(gcf,'WindowButtonMotionFcn','');
set(gcf,'WindowButtonUpFcn','');
set(gcf,'doublebuffer','off');
h   = get(gcf,'CurrentObject');
editField(h,[]);


function [] = cleanup(obj, event)
% cleans up the figure; specifically we have to delete the handle reference in the main
% window, if it still exists
par     = getappdata(gcbf,'parent');
parms   = getappdata(par,'parameters');
h       = [parms.handle];
i       = find(h==gcbf);     % if this is empty, figure is not linked
if ~isempty(i)
    parms(i).handle = deal(-1);
    setappdata(par,'parameters',parms)
end
delete(gcbf)

function out = me()
out = mfilename;