function fig = ParamFigure(module, params, close_callback)
% Opens or updates a parameter figure window.  This consists of some nice entry fields
% with appropriate tags and callbacks so that when the user edits the value in
% the GUI the corresponding value in WC is altered.
% void ParamFigure(module,[properties,[close_callback]])
%
% If ParamFigure is called without the properties argument, the properties
% already in the wc structure are used to update/open the figure.
%
% properties is a structure with the following fields:
% s.description - a friendly string to put atop the list of params
% s.fieldname.fieldtype - {'String', 'Value', 'List', 'Hidden', or 'Fixed'}
%            .description - String that describes field
%            [.choices] - required for Lists
%            [.value] - String or number that describes initial value
%                       for lists, numbers are indices, and strings are selections
%                       otherwise the value in wc is used
%            [.units] - String describing units of the value
%            [.callback] - if this is supplied for 'Value' or 'String',
%                          altering the value in the field will call the callback
%                          for fixed, a button will be created with the callback
%                          

% $Id$ 
global wc

error(nargchk(1,3,nargin));
module  = lower(module);

% load params from wc if needed
if nargin == 1
    params = GetParam(module);
end
% set the close callback if not supplied
if nargin < 3
    close_callback = @closeFigure;
end
% check for existence of figure
name = [module '.param'];
fig = findobj('tag',name);
if ishandle(fig)
    setParams(module, params)
else
    newFigure(module,params, close_callback)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newFigure(module, params, close_callback)
% Opens a new figure window and sets up the fields for each of the parameters
name = [module '.param'];
fig = findobj('tag',name);
% units are in pixels for my sanity
w_fn = 100;
w_f = 90;
w_units = 15;
h = 23;
x_pad = 5;
y_pad = 5;

% generate function handles for callbacks
fn_read_params = @readParams;
fn_write_params = @writeParams;

% open figure
fig = figure('numbertitle','off','name',name,'tag',name,...
    'DoubleBuffer','off','menubar','none','closerequestfcn',close_callback);
set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

% init fig
paramNames = fieldnames(params);
paramCount = length(paramNames);
h_fig = h * (paramCount + 3);  % 4 extra spots provides padding for buttons and menu
w_fig = w_fn + w_f + w_units + 10;
set(fig,'units','pixels','position',[1040 502 w_fig h_fig]);

% init menus
m = uimenu(fig,'Label','&File');
uimenu(m,'Label','&Load Protocol...','Callback', {fn_read_params, module});
uimenu(m,'Label','&Save Protocol...','Callback', {fn_write_params, module, paramNames});
uimenu(m,'Label','&Close','Callback',{close_callback, fig});

% generate controls
u = uicontrol(fig,'style','pushbutton','String','Close',...
    'position',[(w_fig - w_fn) / 2, x_pad, w_fn, h], 'Callback', {close_callback, fig});

fn_ui = @paramChanged;
for i = 1:paramCount
    y = y_pad + h * (i + 0.5);
    name = paramNames{i};
    s = getfield(params, name);
    InitParam(module, name, s);
    if ~strcmp(lower(s.fieldtype),'hidden')
        u = uicontrol(fig,'style','edit','String',s.description,'tooltipstring',name,...
            'enable','inactive',...
            'position',[x_pad, y, w_fn, h]);
        p = [w_fn + x_pad, y, w_f, h];
        if isfield(s, 'units')
            p_u = [w_fn + w_f + x_pad + x_pad, y + 1, w_units, 18];
            u = uicontrol(fig,'position',p_u,'style','text',...
                'String',s.units);
        end
        %    p = [w_fn + x_pad, y, w_f + x_pad + w_units, h];
        if ~isfield(s,'value')
            wc_param = GetParam(module, name);
            s.value = wc_param.value;
        end
        % first deal with pre-defined custom types ('file_in')
        switch lower(s.fieldtype)
        case 'file_in'
            s.callback = @file_in_btn;
        end
        switch lower(s.fieldtype)
        case {'string','value'}
            st = {'style','edit','BackgroundColor','white',...
                    'HorizontalAlignment','right'};
        case 'list'
            st = {'style','popupmenu','string',s.choices,'BackgroundColor','white'};
        case {'fixed','file_in'}
            st = {'style','edit','enable','inactive'};
            % create button if .callback is specified
            if isfield(s,'callback')
                p_u = [w_fn + w_f + x_pad + x_pad, y + 2, w_units/2, 18];
                cb = s.callback;
                u = uicontrol(fig,'position',p_u,'style','pushbutton',...
                    'String','','Callback', {cb, module, name, s});        
            end
        end
        t = [module '.' name];
        u = uicontrol(fig,'position',p,st{:},'tag', t,...
            'callback',{fn_ui, module, name, s});
        s.value = setValue(u,s);
    end
    params = setfield(params,name,s);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function setParams(module, struct)
% updates the GUI and wc structure with values in STRUCT
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

        
function v = setValue(handle, struct)
% sets the param value in the GUI
switch lower(struct.fieldtype)
case 'list'
    c = struct.choices;
    set(handle,'String',c);
    v = struct.value;
    if ~isnumeric(v)
        v = strmatch(v, struct.choices);
    end
    if ~isempty(v)
        set(handle,'Value',v);
        v = struct.choices{v};
    end
otherwise
    v = num2str(struct.value);
    set(handle,'String',v,'tooltipstring',v);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function file_in_btn(varargin)
% handles button presses for file selection
mod = varargin{3};
param = varargin{4};
s = varargin{5};
t = [mod '.' param];
h = findobj(gcbf,'tag',t);
v = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2] = uigetfile([pn filesep '*.mat']);
if ~isnumeric(fn2)
    v = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s = SetParam(mod, param, v);
end

function paramChanged(varargin)
% when a parameter changes, we have to update the wc structure
% and call the callback, if one is specified in the structure.
mod = varargin{3};
param = varargin{4};
s = varargin{5};
% process the data
h = varargin{1};
v = getValue(h, lower(s.fieldtype));
s = SetParam(mod, param, v);
if isfield(s,'callback')
    feval(s.callback, mod, param, s);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function readParams(varargin)
mod = varargin{3};
[fn pn] = uigetfile('*.mat');
if isnumeric(pn)
    return
end
pnfn = fullfile(pn,fn);
if exist(pnfn)
    s = load(pnfn);
    s = removeFixed(s);
    setParams(mod, s);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeParams(varargin)
mod = varargin{3};
fns = varargin{4};
[fn pn] = uiputfile('*.mat');
if isnumeric(pn)
    return
end
pnfn = fullfile(pn,fn);
s = GetParam(mod);
WriteStructure(pnfn,s);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = removeFixed(s)
% removes 'fixed' fieldtypes from a param structure, which
% is necessary to avoid writing over fixed values that
% reflect some critical property of the hardware, etc
n = fieldnames(s);
for i = 1:length(n)
    p = getfield(s,n{i});
    type = getfield(p,'fieldtype');
    if strcmp(lower(type),'fixed')
        s = rmfield(s, n{i});
    end
end

function closeFigure(varargin)
delete(gcbf);