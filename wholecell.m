function varargout = WholeCell(varargin)
% WHOLECELL Application M-file for WholeCell.fig
%    FIG = WHOLECELL launch WholeCell GUI.
%    WHOLECELL('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 27-Mar-2003 12:01:57

global wc


if nargin > 0
	action = lower(varargin{1});
else
	action = 'init';
end
switch action
    
case 'init'
    
    InitWC;
	fig = openfig(mfilename,'reuse');
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
	wc.wholecell.handles = guihandles(fig);
	guidata(fig, wc.wholecell.handles);
    clfcn = sprintf('%s(''close_Callback'');',me);
    set(fig,'numbertitle','off','name',me,'tag',me,...
        'DoubleBuffer','on','menubar','none','closerequestfcn',clfcn);
    
    initHardware(me);
    if (exist([pwd '\wholecell.mat'],'file') > 0)
        LoadPrefs([pwd '\wholecell.mat']);
    end
    updateChannels;

case 'setup_mode_callback'
    TelegraphSetup('init','mode');
    updateChannels;
case 'setup_gain_callback'
    TelegraphSetup('init','gain');
    updateChannels;
    
case 'ai_add_callback'
    ChannelSetup('add','ai');
    updateChannels;
    
case 'ai_edit_callback'
    channel = get(wc.wholecell.handles.ai_channels,'Value');
    if (channel > 0)
        ChannelSetup('edit','ai',channel);
        updateChannels;
    end
    
case 'ao_add_callback'
    ChannelSetup('add','ao');
    updateChannels;
    
case 'ao_edit_callback'
    channel = get(wc.wholecell.handles.ao_channels,'Value');
    if (channel > 0)
        ChannelSetup('edit','ao',channel);
        updateChannels;
    end
    
case 'amplifier_callback'
    channel = get(wc.wholecell.handles.amplifier,'Value');
    if (channel > 0)
        wc.control.amplifier = wc.ai.Channel(channel);
    end
    
case 'load_prefs_callback'
    LoadPrefs;
    updateChannels;
    
case 'save_prefs_callback'
    SavePrefs(wc);
    
case 'data_dir_callback'
    if (~isempty(wc.control.data_dir))
        cd(wc.control.data_dir);
    end
    [fn pn] = uiputfile({'*.*', 'Filename Ignored'},'Choose a data directory');
    if (pn ~= 0)
        wc.control.data_dir = pn;
        wc.control.data_prefix = fn;
    end
    cd(wc.control.base_dir);
    
case 'seal_test_callback'
    SealTest('init');
    
case 'wcdump_callback';
    keyboard;
    
case 'close_callback'
    clear wc;
    daqreset;
    DeleteFigure(me);
    
otherwise
    disp([action ' is not supported.']);
end



% local functions

function out = me()
out = mfilename;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setString(tag,text)
global wc
try
    sf = sprintf('wc.wholecell.handles.%s',tag);
    obj = eval(sf);
    set(obj,'String',text);
catch
    disp(['No such object ' tag]);
end
%%%%%%%%%%%%%%%%%%%%%%%5
function initHardware(module)
global wc

InitDAQ(5000);

setString('device',wc.control.DeviceName);
setString('adaptor',wc.control.AdaptorName);
setString('totalchannels',num2str(wc.control.TotalChannels));
setString('coupling',wc.control.Coupling);
setString('samplingrate',wc.control.SampleRate);
setString('status',get(wc.ai,'Running'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function updateChannels()
% refreshes the channel lists
global wc
% input:
cs = '';
c = get(wc.ai.Channel,{'HwChannel','ChannelName','Units'});
for i=1:size(c,1);
    cs{i} = sprintf('%i: %s (%s)', c{i,1}, c{i,2}, c{i,3});
end
set(wc.wholecell.handles.ai_channels,'String',cs);
% amplifier selection
if (~isempty(wc.control.amplifier))
    selected = wc.control.amplifier.Index;
else
    selected = 1;
end
if (length(cs) > 0)
    set(wc.wholecell.handles.amplifier,'String',cs);
    set(wc.wholecell.handles.amplifier,'Value',selected);
    wc.control.amplifier = wc.ai.Channel(selected);
else
    set(wc.wholecell.handles.amplifier,'String',' ');
    set(wc.wholecell.handles.amplifier,'Value',1);
    wc.control.amplifier = [];
end

% output
cs = '';
c = get(wc.ao.Channel,{'HwChannel','ChannelName', 'Units'});
for i=1:size(c,1);
    cs{i} = sprintf('%i: %s (%s)', c{i,1}, c{i,2}, c{i,3});
end
set(wc.wholecell.handles.ao_channels,'String',cs);

    

% --------------------------------------------------------------------
function varargout = ai_channels_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ai_channels.
disp('ai_channels Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ai_add_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ai_add.
disp('ai_add Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ai_edit_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ai_edit.
disp('ai_edit Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ai_delete_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ai_delete.
disp('ai_delete Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ao_channels_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ao_channels.
disp('ao_channels Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ao_add_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ao_add.
disp('ao_add Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ao_edit_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ao_edit.
disp('ao_edit Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = ao_delete_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ao_delete.
disp('ao_delete Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_0_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_0.
disp('dio_0 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_1_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_1.
disp('dio_1 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_2_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_2.
disp('dio_2 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_3_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_3.
disp('dio_3 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_4_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_4.
disp('dio_4 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_5_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_5.
disp('dio_5 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_6_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_6.
disp('dio_6 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_7_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio_7.
disp('dio_7 Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = scope_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.scope.
disp('scope Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = record_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.record.
disp('record Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = stop_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.stop.
disp('stop Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = amplifier_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.amplifier.
disp('amplifier Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = wcdump_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.wcdump.
disp('wcdump Callback not implemented yet.')