function varargout = ChannelSetup(varargin)
% CHANNELSETUP Application M-file for TelegraphSetup.fig
%    FIG = CHANNELSETUP launch TelegraphSetup GUI.
%    CHANNELSETUP(action,type,[index])
%    action is either 'add' or 'edit'
%    type is 'ai' or 'ao'
%    index is required for 'edit' action

%   This function sets up a channel.
%
% $Id$
global wc

if nargin > 0
	action = lower(varargin{1});
else
	action = 'init';
end

switch action

case 'add'
    
    type = lower(varargin{2});
    sf = sprintf('wc.%s',type);
    daq = eval(sf);
    
    OpenGuideFigure(me,'WindowStyle','modal');

    indices = daq.Channel.Index;
    nextIndex = max([daq.Channel.Index{:}]) + 1;
    set(wc.channelsetup.handles.index,'String',nextIndex);
    
    availableChannels = setdiff(wc.control.channels, wc.control.usedChannels);
    channels = ['  '; num2str(availableChannels')];
    set(wc.channelsetup.handles.channels,'String',channels);
        
    set(wc.channelsetup.handles.channels,'Value',1);
    
	% Wait for callbacks to run and window to be dismissed:
	uiwait(wc.channelsetup.fig);
    
case 'edit'
    
    type = lower(varargin{2});
    index = varargin{3};
    sf = sprintf('wc.%s',type);
    daq = eval(sf);
    
    OpenGuideFigure(me,'WindowStyle','modal');
    
    set(wc.channelsetup.handles.index,'String',index);
    availableChannels = setdiff(wc.control.channels, wc.control.usedChannels);
    channels = ['  '; num2str(availableChannels')];
    set(wc.channelsetup.handles.channels,'String',channels);

    channel = daq.Channel(index);
    set(wc.channelsetup.handles.channels,'Value',find(availableChannels==channel.HwChannel) + 1);
    set(wc.channelsetup.handles.name,'String',channel.ChannelName);
    set(wc.channelsetup.handles.units,'String',channel.Units);
    gain = channel.SensorRange ./ channel.UnitsRange;
    set(wc.channelsetup.handles.gain,'String',num2Str(gain(1)));

    % Wait for callbacks to run and window to be dismissed:
	uiwait(wc.channelsetup.fig);
    
    
case 'ok_callback'
    % when the user presses OK this module opens the channel
    % or if it already exists, reconfigures it
    choice = get(wc.channelsetup.handles.channels,'Value');
    channels = get(wc.channelsetup.handles.channels,'String');
    choice = channels(choice,:);
    if (isempty(choice))
        % do nothing
    else
        makeChannel(choice);
    end
    uiresume(wc.channelsetup.fig);
    delete(gcbf);
    
case {'cancel_callback' 'close_callback'}
    uiresume(wc.channelsetup.fig);
    delete(gcbf);
    
otherwise

end


% private functions
function out = me()
out = mfilename;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function channels = getChannels()
% returns a vector of hardware channels in use
global wc
channels = wc.control.usedChannels;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makeChannel(channelName)
% creates a channel
% channelName - a string identifying the channel hardware number
global wc

    % figure out whether to make a channel
    channels = getChannels;
    channel = str2num(channelName);
    channelIndex = find(channels==channel);
    if (~isempty(channelIndex))
        c = wc.ai.Channel(channelIndex);  % channels have to be indexed by Index, not HwChannel
    else
        c = addchannel(wc.ai,channel);
    end
    % set up the channel
    set(c, 'ChannelName', [wc.telegraphsetup.lineName ' telegraph']);
    range = [-10 10];
    set(c, {'InputRange','SensorRange','UnitsRange'}, {range, range, range});
    sf = sprintf('wc.control.telegraph.%s=channelIndex;',wc.telegraphsetup.lineName);
    eval(sf,'disp(sf)');
