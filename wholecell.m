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
    channel = GetUIParam(me, 'ai_channels', 'Value');
    if (channel > 0)
        ChannelSetup('edit','ai',channel);
        updateChannels;
    end
    
case 'ao_add_callback'
    ChannelSetup('add','ao');
    updateChannels;
    
case 'ao_edit_callback'
    channel = GetUIParam(me, 'ao_channels', 'Value');
    if (channel > 0)
        ChannelSetup('edit','ao',channel);
        updateChannels;
    end
    
case 'amplifier_callback'
    channel = GetUIParam(me, 'amplifier', 'Value');
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
%%%%%%%%%%%%%%%%%%%%%%%5
function initHardware(module)
global wc

InitDAQ(5000);

SetUIParam(me,'device','String',wc.control.DeviceName);
SetUIParam(me,'adaptor','String',wc.control.AdaptorName);
SetUIParam(me,'totalchannels','String',num2str(wc.control.TotalChannels));
SetUIParam(me,'coupling','String',wc.control.Coupling);
SetUIParam(me,'samplingrate','String',wc.control.SampleRate);
SetUIParam(me,'status','String',get(wc.ai,'Running'));

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
SetUIParam(me,'ai_channels','String',cs);

% amplifier selection
if (~isempty(wc.control.amplifier))
    selected = wc.control.amplifier.Index;
else
    selected = 1;
end
if (length(cs) > 0)
    SetUIParam(me,'amplifier',{'String','Value'},{cs,selected});
    wc.control.amplifier = wc.ai.Channel(selected);
else
    SetUIParam(me,'amplifier',{'String','Value'},{' ',1});
    wc.control.amplifier = [];
end

% output
cs = '';
c = get(wc.ao.Channel,{'HwChannel','ChannelName', 'Units'});
for i=1:size(c,1);
    cs{i} = sprintf('%i: %s (%s)', c{i,1}, c{i,2}, c{i,3});
end
SetUIParam(me,'ao_channels','String',cs);
