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
    
    fig = createFigure
    
% case 'data_dir_callback'
%     if exist(wc.control.data_dir,'dir') == 7
%         cd(wc.control.data_dir);
%     end
%     pn = uigetdir;
%     if (pn ~= 0)
%         wc.control.data_dir = pn;
%         set(wc.ai,'LogFileName',NextDataFile);
%     end
%     cd(wc.control.base_dir);
% 
% case 'data_prefix_callback'
%     def = wc.control.data_prefix;
%     if isempty(def) | ~ischar(def)
%         def = '';
%     end
%     a = inputdlg('Enter a prefix for subsequent data files','Data Prefix',...
%         1,{def});
%     if ~isempty(a)
%         wc.control.data_prefix = a{1};
%     end
    
case 'seal_test'
    SealTest('init');
    
% case 'start_scope_callback'
%     GapFree('start');
    
case 'record_protocol'
    if (isempty(wc.control.protocol))
        GapFree('record');
    else
        feval(wc.control.protocol,'record')
    end
    
case 'stop_protocol'
    if (isempty(wc.control.protocol))
        StopAcquisition(me,[wc.ai wc.ao]);
    else
        feval(wc.control.protocol,'stop')
    end

case 'start_protocol'
    func = wc.control.protocol;
    if (isempty(func))
        pnfn = GetUIParam(me,'protocolStatus','String');
        [a func] = fileparts(pnfn);
    end
    if (exist(func) > 0)
        feval(func,'start');
    else
        WholeCell('load_protocol_callback');
    end
%     
% case 'load_protocol_callback'
%     [fn pn] = uigetfile('*.m', 'Pick an M-file');
%     if (isstr(fn))
%         SetUIParam(me,'protocolStatus','String',[pn fn]);
%         [a func] = fileparts(fn);
%         wc.control.protocol = func;
%         feval(func, 'init'); % this assumes the file is the current directory
%     end
    
case 'init_protocol'
    func = GetParam(me,'protocol');
    feval(func, 'reinit');
    
case 'close_callback'
    DeleteFigure(me);
    
otherwise
    disp([action ' is not supported.']);
end

% local functions

function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatewc(varargin)
% updates the wc control structure with critical values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pick(varargin)
% opens a window that allows the user to pick a file/path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = createFigure()
% generates the figure window & its denizens
global wc;
h = figure;
set(h,'units','pixels','position',[289 900 800 60],...
    'tag',me,'name',me,...
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
              {'position', [75 5 150 18],'backgroundcolor',[1 1 1],'String',s,...
                  'style','edit','fontsize',6,'Callback',upd});
s = wc.control.data_dir;
InitUIControl(me, 'data_dir',...
              {'position', [75 24 150 18],'backgroundcolor',[1 1 1],'String',s,...
                  'style','edit','fontsize',6,'Callback',upd});
s = wc.control.protocol;          
InitUIControl(me, 'protocol',...
              {'position', [75 43 150 18],'backgroundcolor',[1 1 1],'String',s,...
                  'style','edit','fontsize',6,'Callback',upd});
% pick buttons
fn_pick = @pick;
InitUIControl(me, 'protocol_btn',...
              {'position', [228 43 12 16],'String','',...
                  'style','pushbutton','Callback', fn_pick});
InitUIControl(me, 'data_dir_btn',...
              {'position', [228 24 12 16],'String','',...
                  'style','pushbutton','Callback', fn_pick});
% command buttons
InitUIControl(me, 'init_protocol',...
              {'position',[253 30 100 25],'String','Init','Callback',...
                  'ProtocolControl(''init_protocol'')','style','pushbutton'});
InitUIControl(me, 'play_protocol',...
              {'position',[363 30 100 25],'String','Play','Callback',...
                  'ProtocolControl(''play_protocol'')','style','pushbutton'});
InitUIControl(me, 'record_protocol',...
              {'position',[473 30 100 25],'String','Record','Callback',...
                  'ProtocolControl(''record_protocol'')','style','pushbutton'});
InitUIControl(me, 'stop_protocol',...
              {'position',[583 30 100 25],'String','Stop','Callback',...
                  'ProtocolControl(''stop_protocol'')','style','pushbutton'});
InitUIControl(me, 'seal_test',...
              {'position',[693 30 100 25],'String','Seal Test','Callback',...
                  'ProtocolControl(''seal_test'')','style','pushbutton'});
% status bar
InitUIControl(me, 'status',...
              {'position',[254 0 526 17],'String','(status)','style','text'});
