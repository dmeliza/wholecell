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
    OpenGuideFigure(me,'WindowStyle','modal');
    
    if nargin > 1
        wc.telegraphsetup.lineName = varargin{2};
    end
    if nargin > 2
        channel = varargin{3};
    else
        channel = 0;
    end
    
    availableChannels = setdiff(wc.control.channels, wc.control.usedChannels);
    channels = ['  '; num2str(availableChannels')];
    set(wc.telegraphsetup.handles.channels,'String',channels);
    set(wc.telegraphsetup.handles.channels,'Value',1);  % TODO: set to current value
    set(wc.telegraphsetup.handles.line,'String',wc.telegraphsetup.lineName);
    
	% Wait for callbacks to run and window to be dismissed:
	uiwait(wc.telegraphsetup.fig);
    
    

case 'ok_callback'
    % when the user presses OK this module opens the channel
    % or if it already exists, reconfigures it
    choice = get(wc.telegraphsetup.handles.channels,'Value');
    channels = get(wc.telegraphsetup.handles.channels,'String');
    choice = channels(choice,:);
    if (isempty(choice))
        % do nothing
    else
        makeTelegraph(choice);
    end
    uiresume(wc.telegraphsetup.fig);
    delete(wc.telegraphsetup.fig);
    
case {'cancel_callback' 'close_callback'}
    uiresume(wc.telegraphsetup.fig);
    delete(wc.telegraphsetup.fig);
    
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
function makeTelegraph(channelName)
global wc

    % figure out whether to make a channel
    channel = str2num(channelName);
    channelIndex = find(getChannels==channel);
    if (~isempty(channelIndex))
        c = wc.ai.Channel(channelIndex);  % channels have to be indexed by Index, not HwChannel
    else
        c = CreateChannel(wc.ai, channel);
    end
    % set up the channel
    set(c, 'ChannelName', [wc.telegraphsetup.lineName ' telegraph']);
    range = [-10 10];
    set(c, {'InputRange','SensorRange','UnitsRange'}, {range, range, range});
    sf = sprintf('wc.control.telegraph.%s=channelIndex;',wc.telegraphsetup.lineName);
    eval(sf,'disp(sf)');
