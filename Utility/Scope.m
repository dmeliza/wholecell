function Scope(varargin)
% The Scope is a general purpose figure used to display stuff.
% Multiple scopes can be opened 
%
% $Id$

global wc

if nargin > 0
	action = lower(varargin{1});
else
	action = 'init';
end
switch action
    
case 'init'

    if nargin > 1
        tag = varargin{2};
    else
        tag = me;
    end
    fig = OpenGuideFigure(me, tag);
    zoom(fig,'off');
    
case 'plot'
    % when this callback is called, the remaining varargins are used
    % to plot data on the scope, with the first argument definining the
    % method used.  eg: Scope('plot','plot',time,data)
    handler = @axesclick;
    handles = [];
    if nargin > 1
        scope = getScopeHandle(me);
        handles = feval(varargin{2:nargin},'Parent',scope);
        set(scope,'ButtonDownFcn',handler);
    end
    if ~isempty(handles)
       h = handles(find(ishandle(handles))); % selects valid handles
       handler = @axesclick;
       set(h,'ButtonDownFcn',handler);
    end
    
case 'scroll'
    scrollplot(varargin{2:nargin});
    
case 'scopeplot'
    scopeplot(varargin{2:nargin}); 
    
case 'clear'
    scope = getScopeHandle(me);
    kids = get(scope, 'Children');
    delete(kids);
    set(scope,'UserData',[]);
    
case 'xshrink_callback'
    xlim = GetUIParam(me,'scope','XLim');
    SetUIParam(me,'scope','XLim',[0 xlim(2) * 1.2]);

case 'xstretch_callback'
    xlim = GetUIParam(me,'scope','XLim');
    SetUIParam(me,'scope','XLim',[0 xlim(2) * .8]);
    
case 'yshrink_callback'
    c = getCenter;
    setCenter(c,[1 1.2]);
    
case 'ystretch_callback'
    c = getCenter;
    setCenter(c,[1 0.8])
    
case 'close_callback'
    disp('Stopping protocol');
    %ProtocolControl('stop_callback');
    pause(1)
    DeleteFigure(me);
    
otherwise
    disp([action ' is not supported.']);
end

%%%%%%%%%%%%%functions
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%5
function scope = getScopeHandle(tag)
scope = GetUIHandle(tag,'scope');
if ~ishandle(scope)
    Scope('init', tag);
    scope = GetUIHandle(tag,'scope');
end

%%%%%%%%%%%%%%%%%%%%%%%
function scrollplot(time, data, varargin)
% when this callback is called, the scope plots the data in scrolling
% mode.  eg: Scope('scroll',time,data,xlim), where xlim defines the
% width of the graph.  Old data is not deleted, so we may have issues
% if the graph runs too long.
handler = @axesclick;
handles = [];
if nargin > 1
    scope = getScopeHandle(me);
    last = time(length(time));
    if nargin > 2
        xlim = [last - varargin{3}, last];
    else
        xlim = diff(get(scope,'XLim'));
        xlim = [last - xlim, last];
    end
    handles = plot(time, data, 'Parent', scope); % data is plotted
    set(scope,'ButtonDownFcn',handler,'XLim',xlim);
end
if ~isempty(handles)
    h = handles(find(ishandle(handles))); % selects valid handles
    handler = @axesclick;
    set(h,'ButtonDownFcn',handler);
end

%%%%%%%%%%%%%%%%%%%%%%%
function scopeplot(time, data, varargin)
% this callback does a scope-style plot of the data, moving data that
% goes past the x limit of the graph to the beginning
handler = @axesclick;
scope = getScopeHandle(me);
k = get(scope,'UserData');
if isempty(k)
    k = plot(time, data, 'Parent', scope);
    set(scope,'ButtonDownFcn', handler, 'UserData', k);
    stripchart('initialize', scope, 'Time(ms)');
else
    % currently just plots the first trace
    if iscell(k) k = k{1}; end
    stripchart('update', k, time', data(:,1)');
end

%%%%%%%%%%%%%%%%%%%%55
function out = dims(axishandle)
lims = axis(axishandle);
out = [diff(lims(1:2)) diff(lims(3:4))];

%%%%%%%%%%%%%%%%%%%%%%%%%
function out = getCenter()
ah = GetUIHandle(me,'scope');
lims = axis(ah);
out = [mean(lims(1:2)) mean(lims(3:4))];

%%%%%%%%%%%%%%%%%%%%%5
function setCenter(point, scalefactor)
% sets the center of an axes to a supplied value with or without scaling
ah = GetUIHandle(me,'scope');
dim = dims(ah) .* scalefactor;
adj = reshape([-dim/2; +dim/2], 1, 4);
newlims = adj + reshape([point;point],1,4);
axis(ah, newlims);

% %%%%%%%%%%%%%%%%%%%%%
function axesclick(varargin)
% handler for clicks in the axes, which get passed funny values
% that screw up my switchyard.
% sets the center point (eventually we'd like to let the user drag things around)
scope = GetUIHandle(me,'scope');
pt = get(scope,'currentpoint');
button = get(gcbf,'SelectionType');
switch button
case 'normal'
    % re-center graph
    setCenter([pt(1,1) pt(1,2)],1);
otherwise
    % reset axis limits
    axis(scope,'auto');
end