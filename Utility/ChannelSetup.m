function channel = ChannelSetup(varargin)
% CHANNELSETUP Application M-file for TelegraphSetup.fig
%    channel = CHANNELSETUP(action,type,([name]|index))
%    action is either 'add' or 'edit'
%    type is 'ai' or 'ao'
%    name is optional for 'add' action
%    index is required for 'edit' action, and name is not accepted

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
    fig = OpenGuideFigure(me);
    set(fig,'WindowStyle','modal');
    
    type = lower(varargin{2});
    if (nargin > 2)
        SetUIParam(me, 'name', {'String','Enable'}, {varargin{3},'Off'});
    end
    daq = sprintf('wc.%s',type);
    wc.channelsetup.daq = eval(daq);
    wc.channelsetup.control = eval(sprintf('wc.control.%s',type));
    wc.channelsetup.channel = [];
    
    SetUIParam(me, 'type', 'String', type);
    
    indices = wc.channelsetup.daq.Channel.Index;
    nextIndex = length(indices) + 1;
    SetUIParam(me, 'index', 'String', nextIndex); 
    
    availables = setdiff(wc.channelsetup.control.channels, wc.channelsetup.control.usedChannels);
    availables = num2str(availables');
    channels = char(' ', availables);
    SetUIParam(me, 'channels', {'String', 'Value'}, {channels, 1}); 
    
	% Wait for callbacks to run and window to be dismissed:
	uiwait(fig);
    
case 'edit'
    fig = OpenGuideFigure(me);
    set(fig,'WindowStyle','modal');
    
    type = lower(varargin{2});
    index = varargin{3};
    daq = sprintf('wc.%s',type);
    wc.channelsetup.daq = eval(daq);
    wc.channelsetup.control = eval(sprintf('wc.control.%s',type)); 
    wc.channelsetup.channel = wc.channelsetup.daq.Channel(index);

    SetUIParam(me, 'type', 'String', type); 
    SetUIParam(me, 'index', 'String', index); 
    % include the current channel first
    availableChannels = [wc.channelsetup.channel.HwChannel;...
            setdiff(wc.channelsetup.control.channels, wc.channelsetup.control.usedChannels)']; 
    channels = num2str(availableChannels);
    SetUIParam(me, 'channels', {'String','Value'}, {channels, 1}); 

    SetUIParam(me, 'name', 'String', wc.channelsetup.channel.ChannelName);
    SetUIParam(me, 'units', 'String', wc.channelsetup.channel.Units);
    gain = ChannelGain(wc.channelsetup.channel,'get');
    SetUIParam(me, 'gain', 'String', num2str(gain(1)));

    % Wait for callbacks to run and window to be dismissed:
	uiwait(fig);
    
    
case 'ok_callback'
    % when the user presses OK this module opens the channel
    % or if it already exists, reconfigures it
    type = get(wc.channelsetup.handles.type,'String');
    choice = get(wc.channelsetup.handles.channels,'Value');
    channels = get(wc.channelsetup.handles.channels,'String');
    choice = channels(choice,:);
    if (isempty(choice))
        c = [];
    else
        c = makeChannel(type, choice);
    end
    uiresume(wc.channelsetup.fig);
    DeleteFigure(me);
    
case {'cancel_callback' 'close_callback'}
    uiresume(wc.channelsetup.fig);
    DeleteFigure(me);
    
otherwise

end


% private functions
function out = me()
out = mfilename;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function channels = getChannels()
% returns a vector of hardware channels in use
global wc
channels = wc.channelsetup.control.usedChannels;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c = makeChannel(type, channelName)
% creates a channel
% type - ai or ao
% channelName - a string identifying the channel hardware number
global wc

channel = str2num(channelName);
% figure out whether to make a channel
if (~isempty(wc.channelsetup.channel))
    c = ReassignChannel(wc.channelsetup.channel, channel);
else
    c = CreateChannel(wc.channelsetup.daq,channel);
end

set(c, 'ChannelName', get(wc.channelsetup.handles.name,'String'));
set(c, 'Units', get(wc.channelsetup.handles.units,'String'));
gain = str2num(get(wc.channelsetup.handles.gain,'String'));
if (isempty(gain))
    gain = 1;
end
range = [-5 5];
ChannelGain(c,'set',gain);
%set(c, {'InputRange','SensorRange','UnitsRange'}, {range, range, range * gain});
