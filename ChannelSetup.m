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
    OpenGuideFigure(me,'WindowStyle','modal');
    
    type = lower(varargin{2});
    daq = sprintf('wc.%s',type);
    wc.channelsetup.daq = eval(daq);
    wc.channelsetup.control = eval(sprintf('wc.control.%s',type));
    
    set(wc.channelsetup.handles.type,'String',type);
    
    indices = wc.channelsetup.daq.Channel.Index;
    nextIndex = length(indices) + 1;
    set(wc.channelsetup.handles.index,'String',nextIndex);
    
    availables = setdiff(wc.channelsetup.control.channels, wc.channelsetup.control.usedChannels);
    availables = num2str(availables');
    channels = char(' ', availables);
    set(wc.channelsetup.handles.channels,'String',channels);
        
    set(wc.channelsetup.handles.channels,'Value',1);
    
	% Wait for callbacks to run and window to be dismissed:
	uiwait(wc.channelsetup.fig);
    
case 'edit'
    OpenGuideFigure(me,'WindowStyle','modal');
    
    type = lower(varargin{2});
    index = varargin{3};
    daq = sprintf('wc.%s',type);
    wc.channelsetup.daq = eval(daq);
    wc.channelsetup.control = eval(sprintf('wc.control.%s',type));
    wc.channelsetup.channel = wc.channelsetup.daq.Channel(index);

    set(wc.channelsetup.handles.type,'String',type);    
    set(wc.channelsetup.handles.index,'String',index);
    % include the current channel first
    availableChannels = [wc.channelsetup.channel.HwChannel;...
            setdiff(wc.channelsetup.control.channels, wc.channelsetup.control.usedChannels)']; 
    channels = num2str(availableChannels);
    set(wc.channelsetup.handles.channels,'String',channels);

    set(wc.channelsetup.handles.channels,'Value',1);
    set(wc.channelsetup.handles.name,'String',wc.channelsetup.channel.ChannelName);
    set(wc.channelsetup.handles.units,'String',wc.channelsetup.channel.Units);
    gain = ChannelGain(wc.channelsetup.channel,'get');
    set(wc.channelsetup.handles.gain,'String',num2Str(gain(1)));

    % Wait for callbacks to run and window to be dismissed:
	uiwait(wc.channelsetup.fig);
    
    
case 'ok_callback'
    % when the user presses OK this module opens the channel
    % or if it already exists, reconfigures it
    type = get(wc.channelsetup.handles.type,'String');
    choice = get(wc.channelsetup.handles.channels,'Value');
    channels = get(wc.channelsetup.handles.channels,'String');
    choice = channels(choice,:);
    if (isempty(choice))
        % do nothing
    else
        makeChannel(type, choice);
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
function makeChannel(type, channelName)
% creates a channel
% type - ai or ao
% channelName - a string identifying the channel hardware number
global wc

channel = str2num(channelName);
% figure out whether to make a channel
if (isfield(wc.channelsetup,'channel'))
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
