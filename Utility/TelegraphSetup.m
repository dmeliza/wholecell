function varargout = TelegraphSetup(varargin)
% TELEGRAPHSETUP Application M-file for TelegraphSetup.fig
%    TELEGRAPHSETUP(action,lineName) invoke the named callback.
%   
%   Currently the only supported action is 'init'
%
%   This function sets up telegraphing.  Telegraphs work by storing
%   information about the telegraph channel in the wc.control object,
%   which is then used by the SweepAcquired function to scale the data
%   and apply the correct units.
%
%   Telegraphs for the axoclamp 200B
% 
%   Gain:
%    0.5 - 2 V
%   1   - 2.5 V
%   etc (0.5 V steps)
%   500 - 6.5 V
% 
%   Mode:
%   Track - 4 V
%   VClamp - 6 V
%   I=0    - 3 V
%   IClamp - 2 V
%   Fast Ic - 1 V
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
    fig = OpenGuideFigure(me);
    set(fig,'WindowStyle','modal');
    
    if nargin > 1
        linename = varargin{2};
        InitParam(me,'linename', linename);
    end


    c = GetParam('control.telegraph', linename);
    if (~isempty(c))
        currentchannel = wc.ai.Channel(c).HwChannel;
        availableChannels = [setdiff(wc.control.ai.channels, wc.control.ai.usedChannels)];
        channels = char(num2str(currentchannel),num2str(availableChannels'));
    else
        currentchannel = 1;
        availableChannels = setdiff(wc.control.ai.channels, wc.control.ai.usedChannels);
        channels = char(' ',num2str(availableChannels'));
    end

    SetUIParam(me,'channels',{'String', 'Value'}, {channels, 1});
    SetUIParam(me,'line','String', GetParam(me,'linename'));
    
	% Wait for callbacks to run and window to be dismissed:
	uiwait(wc.telegraphsetup.fig);
    
    

case 'ok_callback'
    % when the user presses OK this module opens the channel
    % or if it already exists, reconfigures it
    choice = GetUIParam(me, 'channels','Value');
    channels = GetUIParam(me, 'channels', 'String');
    choice = channels(choice,:);
    if (isempty(choice))
        % do nothing
    else
        makeTelegraph(choice);
    end
    uiresume(wc.telegraphsetup.fig);
    DeleteFigure(me);
    
case {'cancel_callback' 'close_callback'}
    uiresume(wc.telegraphsetup.fig);
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
channels = wc.control.ai.usedChannels;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c = makeTelegraph(channelName)
global wc

    % figure out whether to make a channel
    channelHW = str2num(channelName);
    linename = GetParam(me,'linename');
    c = GetParam('control.telegraph', linename);
    if (~isempty(c))
        currentchannel = wc.ai.Channel(c);
        c = ReassignChannel(currentchannel, channelHW);
    else
        c = CreateChannel(wc.ai, channelHW);
    end
    % set up the channel
    set(c, 'ChannelName', [GetParam(me, 'linename') ' telegraph']);
    range = [-10 10];
    set(c, {'InputRange','SensorRange','UnitsRange'}, {range, range, range});
    InitParam('control.telegraph', GetParam(me, 'linename'), c.Index);
%     sf = sprintf('wc.control.telegraph.%s=c.Index;',GetParam(me, 'linename'));
%     eval(sf,'disp(sf)');
