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
uimenu(m,'Label','&Load Protocol...','Callback', {fn_read_params, module});
uimenu(m,'Label','&Save Protocol...','Callback', {fn_write_params, module, paramNames});
uimenu(m,'Label','&Close','Callback',{fn_close, fig});

% generate controls
u = uicontrol(fig,'style','pushbutton','String','Close',...
    'position',[(w_fig - w_fn) / 2, x_pad, w_fn, h], 'Callback', {fn_close, fig});

fn_ui = @paramChanged;
for i = 1:paramCount
    y = y_pad + h * (i + 0.5);
    name = paramNames{i};
    s = getfield(params, name);
    InitParam(module, name, s);
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
    if ~isfield(s,'value')
        wc_param = GetParam(module, name);
        s.value = wc_param.value;
    end
    switch lower(s.fieldtype)
    case {'string','value'}
        st = {'style','edit','BackgroundColor','white',...
                'HorizontalAlignment','right'};
    case 'list'
        st = {'style','popupmenu','string',s.choices,'BackgroundColor','white'};
    case 'fixed'
        st = {'style','edit','enable','inactive'};
    end
    t = [module '.' name];
    u = uicontrol(fig,'position',p,st{:},'tag', t,...
        'callback',{fn_ui, module, name, s});
    setValue(u,s);
end

function paramChanged(varargin)
% when a parameter changes, we have to update the wc structure
mod = varargin{3};
param = varargin{4};
s = varargin{5};
% process the data
h = varargin{1};
v = getValue(h, lower(s.fieldtype));
s = SetParam(mod, param, v);

%%%%%%%%%%%%%%%%%%%%%%%
function v = getValue(h, fieldtype)
switch fieldtype
case 'list'
    v = GetSelected(h);
case 'value'
    v = str2num(get(h,'String'));
otherwise
    v = get(h,'String');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function readParams(varargin)
mod = varargin{3};
[fn pn] = uigetfile('*.mat');
pnfn = fullfile(pn,fn);
if exist(pnfn)
    s = load(pnfn);
    setParams(mod, s);
end

function setParams(module, struct)
n = fieldnames(struct);
for i = 1:length(n)
    fn = n{i};
    tag = [module '.' fn];
    h = findobj('tag',tag);
    if ishandle(h)
        s = getfield(struct, fn);
        v = setValue(h, s);
        SetParam(module, fn, v);
    end
end
        
function v = setValue(handle, struct)
% sets the param value in the GUI
switch lower(struct.fieldtype)
case 'list'
    c = struct.choices;
    set(handle,'String',c);
    v = struct.value;
    if ~isnumeric(v)
        s = strmatch(v, struct.choices);
    end
    if ~isempty(s)
        set(handle,'Value',s);
    end
otherwise
    v = num2str(struct.value);
    set(handle,'String',v);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeParams(varargin)
mod = varargin{3};
fns = varargin{4};
[fn pn] = uiputfile('*.mat');
pnfn = fullfile(pn,fn);
for i=1:length(fns)
    sf = sprintf('%s = GetParam(mod, fns{i});', fns{i});
    eval(sf); % creates named variables
end
save(pnfn,fns{:});

function closeFigure(varargin)
close(gcbf);