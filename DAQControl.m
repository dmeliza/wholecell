function DAQControl(varargin)
% DAQControl provides callbacks for a GUI (specified by DAQControl.fig) that
% allows interaction with the data acquisition hardware.  The user can create, edit,
% and delete channels, as well as specify the channels associated with the mode and gain
% telegraphs and the scaled output of an amplifier.
%
% Should be called by wholecell.m
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
    OpenGuideFigure(me);

    initHardware(me);
    if (exist([pwd '\wholecell.mat'],'file') > 0)
        LoadPrefs([pwd '\wholecell.mat']);
    end
    updateChannels;

case 'samplingrate_callback'
    v = str2num(GetUIParam(me,'samplingrate','String'));
    set([wc.ai wc.ao],'SampleRate',v);
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
    
case 'ai_delete_callback'
    channel = getUIParam(me, 'ai_channels', 'Value');
    if (channel > 0)
        delete(wc.ai.Channel(channel));
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
    
case 'ao_delete_callback'
    channel = getUIParam(me, 'ao_channels', 'Value');
    if (channel > 0)
        delete(wc.ao.Channel(channel));
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
    
case 'wcdump_callback';
    keyboard;
    
case 'close_callback'
    WholeCell('destroy');
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

InitDAQ(20000);

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
wc.control.SampleRate = get(wc.ai,'SampleRate');
SetUIParam(me,'samplingrate','String',num2str(wc.control.SampleRate));
% input:
cs = GetChannelList(wc.ai);
SetUIParam(me,'ai_channels','String',cs);
SetUIParam(me,'ai_channels','Value',1);

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
cs = GetChannelList(wc.ao);
SetUIParam(me,'ao_channels','String',cs);
SetUIParam(me,'ao_channels','Value',1);
