function varargout = WholeCell(varargin)
% WHOLECELL Application M-file for WholeCell.fig
%    FIG = WHOLECELL launch WholeCell GUI.
%    WHOLECELL('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 28-Mar-2003 15:41:48

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

    setupFigure(me);
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
%     channel = getUIParam(me, 'ai_channels', 'Value');
%     if (channel > 0)
%         delete(wc.ai.Channel(channel));
%         updateChannels;
%     end
    
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
%     channel = getUIParam(me, 'ao_channels', 'Value');
%     if (channel > 0)
%         delete(wc.ao.Channel(channel));
%         updateChannels;
%     end
    
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
        set(wc.ai,'LogFileName',NextDataFile);
    end
    cd(wc.control.base_dir);
    
case 'seal_test_callback'
    SealTest('init');
    
case 'start_scope_callback'
    GapFree('start');
    
case 'start_record_callback'
    GapFree('record');
    
case 'stop_callback'
    GapFree('stop'); % this will need to change when running protocols

case 'xshrink_callback'
    xlim = GetUIParam(me,'scope','XLim');
    SetUIParam(me,'scope','XLim',[xlim(1) xlim(2) * 1.2]);

case 'xstretch_callback'
    xlim = GetUIParam(me,'scope','XLim');
    SetUIParam(me,'scope','XLim',[xlim(1) xlim(2) * .8]);
    
case 'yshrink_callback'
    xlim = GetUIParam(me,'scope','YLim');
    SetUIParam(me,'scope','YLim',[xlim(1) *1.2, xlim(2) * 1.2]);
    
case 'ystretch_callback'
    xlim = GetUIParam(me,'scope','YLim');
    SetUIParam(me,'scope','YLim',[xlim(1) * .8, xlim(2) * .8]);
    
case 'load_protocol_callback'
    [fn pn] = uigetfile('*.m', 'Pick an M-file');
    SetUIParam(me,'protocolStatus','String',[pn fn]);
    [a func] = fileparts(fn);
    feval(func, 'init'); % this assumes the file is the current directory
    
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

%%%%%%%%%%%%%%%%%%%%%%%%%
function setupFigure(module)

button = imread('button.bmp','bmp');
SetUIParam(me,'yshrink','CData',button);
SetUIParam(me,'ystretch','CData',flipdim(button,1));
button = permute(button,[2 1 3]);
SetUIParam(me,'xstretch','CData',button);
SetUIParam(me,'xshrink','CData',flipdim(button,2));


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


