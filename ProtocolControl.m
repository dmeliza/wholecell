function varargout = ProtocolControl(varargin)
% ProtocolControl is the GUI module used to load and execute protocols (which
% are just mfiles)
%
% Usage: ProtocolControl(action) ['init' is the only "public" action"
%
% 1.3: ProtocolControl.fig is eliminated and the layout significantly changed
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
    
    fig = createFigure;
    
otherwise
    func = GetUIParam(me,'protocol','String');
    funcpath = GetUIParam(me,'protocol','ToolTipString');
end

switch action
    
case 'seal_test'
    SealTest('init');

case 'init_protocol'
    if exist(funcpath,'file') > 0
        feval(func, 'init');
    end    

case 'play_protocol'
    if exist(funcpath,'file') > 0
        feval(func,'start');
    end    
    
case 'record_protocol'
    if exist(funcpath,'file') > 0
        feval(func,'record');
    end    
    
case 'stop_protocol'
    if exist(funcpath,'file') > 0
        feval(func,'stop');
    else
        ClearAI(wc.ai);
        ClearAO(wc.ao);
    end    
    
case 'close_callback'
    DeleteFigure(me);
    
end

% local functions

function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatewc(obj, event)
% updates the wc control structure with critical values
% this is necessary for them to be stored in the prefs file
global wc
wc.control.data_dir = GetUIParam(me,'data_dir','String');
wc.contro.data_prefix = GetUIParam(me,'data_prefix','String');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pick(obj, event)
% opens a window that allows the user to pick a file/path
global wc
t = get(obj,'tag');
i = findstr(t,'_btn');
if isempty(i)
    return
end
tag = t(1:i-1);
switch(tag)
case 'protocol'
    [fn pn] = uigetfile('*.m', 'Pick an M-file');
    if (isstr(fn))
        [a func] = fileparts([pn fn]);
        SetUIParam(me,'protocol','String',[func]);
        SetUIParam(me,'protocol','ToolTipString',[pn fn]);
    end
case 'data_dir'
    curr = GetUIParam(me,'data_dir','String');
    if exist(curr,'dir') == 7
        cd(curr)
    end
    pn = uigetdir;
    if (pn ~= 0)
        SetUIParam(me,'data_dir','String',pn)
        set(wc.ai,'LogFileName',NextDataFile);
    end
    cd(wc.control.base_dir);
end  
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = createFigure()
% generates the figure window & its denizens
global wc;
h = OpenFigure(me,'units','pixels','position',[289 900 800 60],...
    'color',get(0,'defaultUicontrolBackgroundColor'),...
    'resize','off','numbertitle','off','menubar','none',...
    'closerequestfcn','ProtocolControl(''close_callback'')')
% text
uicontrol(h,'position',[10 43 55 14],'style','text',...
          'String','Protocol:');
uicontrol(h,'position',[10 24 55 14],'style','text',...
          'String','Data:');
uicontrol(h,'position',[10 5 55 14],'style','text',...
          'String','Prefix:');
% edits
upd = @updatewc;
s = wc.control.data_prefix;
InitUIControl(me, 'data_prefix',...
              'position', [75 5 150 18],'backgroundcolor',[1 1 1],'String',s,...
                  'style','edit','fontsize',6,'Callback',upd);
s = wc.control.data_dir;
InitUIControl(me, 'data_dir',...
              'position', [75 24 150 18],'backgroundcolor',[1 1 1],'String',s,...
                  'style','edit','fontsize',6,'enable','inactive');
s = wc.control.protocol;          
InitUIControl(me, 'protocol',...
              'position', [75 43 150 18],'backgroundcolor',[1 1 1],'String',s,...
                  'style','edit','fontsize',6,'enable','inactive');
% pick buttons
fn_pick = @pick;
InitUIControl(me, 'protocol_btn',...
              'position', [228 43 12 16],'String','',...
                  'style','pushbutton','Callback', fn_pick);
InitUIControl(me, 'data_dir_btn',...
              'position', [228 24 12 16],'String','',...
                  'style','pushbutton','Callback', fn_pick);
% command buttons
InitUIControl(me, 'init_protocol',...
              'position',[253 30 100 25],'String','Init','Callback',...
                  'ProtocolControl(''init_protocol'')','style','pushbutton');
InitUIControl(me, 'play_protocol',...
              'position',[363 30 100 25],'String','Play','Callback',...
                  'ProtocolControl(''play_protocol'')','style','pushbutton');
InitUIControl(me, 'record_protocol',...
              'position',[473 30 100 25],'String','Record','Callback',...
                  'ProtocolControl(''record_protocol'')','style','pushbutton');
InitUIControl(me, 'stop_protocol',...
              'position',[583 30 100 25],'String','Stop','Callback',...
                  'ProtocolControl(''stop_protocol'')','style','pushbutton');
InitUIControl(me, 'seal_test',...
              'position',[693 30 100 25],'String','Seal Test','Callback',...
                  'ProtocolControl(''seal_test'')','style','pushbutton');
% status bar
InitUIControl(me, 'status',...
              'position',[254 0 526 17],'String','(status)','style','text');
