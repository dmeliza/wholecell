function fig = OpenParamFigure(module, params)
% Opens a parameter figure window.  This consists of some nice entry fields
% with appropriate tags and callbacks so that when the user edits the value in
% the GUI the corresponding value in WC is altered
% void OpenFigure(module,properties)
%
% properties is a structure with the following fields:
% s.description - a friendly string to put atop the list of params
% s.fieldname.fieldtype - {'String', 'Value', 'List','External' or 'Fixed'}
%            .description - String that describes field
%            [.choices] - required for Lists
%            [.value] - String or number that describes initial value
%                       for lists, numbers are indices, and strings are selections
%                       otherwise the value in wc is used
%            [.units] - String describing units of the value
%            [.callback] - required for Externals - which are represented by
%                          a button (not implemented yet)

% $Id$ 
global wc

if nargin < 2
    error(['Usage: ' me '(module, params)']);
end

% units are in pixels for my sanity
w_fn = 76;
w_f = 95;
w_units = 22;
h = 23;
x_pad = 5;
y_pad = 5;

% generate function handles for callbacks
fn_read_params = @readParams;
fn_write_params = @writeParams;
fn_close = @closeFigure;

name = [module '.param'];
fig = findobj('tag',name);
if ishandle(fig)
    return % need to load new values if this happens...
end
fig = figure('numbertitle','off','name',name,'tag',name,...
    'DoubleBuffer','off','menubar','none');
set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
%set(fig,'Visible','off');

% init fig
paramNames = fieldnames(params);
paramCount = length(paramNames);
h_fig = h * (paramCount + 3);  % 4 extra spots provides padding for buttons and menu
w_fig = w_fn + w_f + w_units + 20;
set(fig,'units','pixels','position',[1040 502 w_fig h_fig]);

% init menus
m = uimenu(fig,'Label','&File');
uimenu(m,'Label','&Load Protocol...','Callback', {fn_read_params, fig});
uimenu(m,'Label','&Save Protocol...','Callback', {fn_write_params, fig});
uimenu(m,'Label','&Close','Callback',{fn_close, fig});

% generate controls
u = uicontrol(fig,'style','pushbutton','String','Close',...
    'position',[(w_fig - w_fn) / 2, x_pad, w_fn, h], 'Callback', {fn_close, fig});

for i = 1:paramCount
    y = y_pad + h * (i + 0.5);
    name = paramNames{i};
    s = getfield(params, name);
    u = uicontrol(fig,'style','edit','String',s.description,'enable','inactive',...
        'position',[x_pad, y, w_fn, h]);
    if isfield(s, 'units')
        p = [w_fn + x_pad, y, w_f, h];
        p_u = [w_fn + w_f + x_pad + x_pad, y + 1, w_units, 18];
        u = uicontrol(fig,'position',p_u,'style','text',...
            'String',s.units);
    else
        p = [w_fn + x_pad, y, w_f + x_pad + w_units, h];
    end
    if isfield(s,'value')
        v = s.value;
    else
        v = GetParam(module, name);
    end
    switch lower(s.fieldtype)
    case {'string','value'}
        if isnumeric(v)
            v = num2str(v);
        end
        st = {'style','edit','BackgroundColor','white',...
                'HorizontalAlignment','right','String',v};
    case 'list'
        st = {'style','listbox','string',s.choices};
        if ~isnumeric(v)
            v = strmatch(v, s.choices);
        end
        if ~isempty(v)
            st = {st{:}, 'value', v};
        end
    case 'fixed'
        if isnumeric(v)
            v = num2str(v);
        end
        st = {'style','edit','enable','inactive','String',v};
    end
    t = [module '.' name];
    u = uicontrol(fig,'position',p,st{:},'tag', t);
        
end

% u = uicontrol(fig,'style','text','string',s.description,'fontsize',12);
% e = get(u,'extent');
% set(u,'position',[(w_fig - e(3))/2, y + h + y_pad * 2, e(3), e(4)]);
    
% if nargin > 2
%     properties = varargin{1};
%     values = varargin{2};
%     set(obj.fig, properties, values);
% end
% 
% sf = sprintf('wc.%s = obj;',module);
% eval(sf);
% fig = obj.fig;

function readParams(varargin)
disp(varargin);

function writeParams(varargin)
disp(varargin);

function closeFigure(varargin)
close(gcbf);