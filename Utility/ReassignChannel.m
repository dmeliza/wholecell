function channel = ReassignChannel(channel, hwindex, varargin)
% reassigns a Matlab channel to another hardware channel
% channel = ReassignChannel(daq, hwindex, [{properties}, {values}])
% doesn't do any checking to see if the channel is free, so be careful
%
% $Id$
global wc

old = get(channel, 'HwChannel');
set(channel, 'HwChannel', hwindex);
if nargin > 3
    properties = varargin{1};
    values = varargin{2};
    set(channel, properties, values);
end

daq = channel.Parent;
usedChannels = daq.Channel.HwChannel;
if (length(usedChannels) == 1)
    wc.control.usedChannels = usedChannels;
else
    wc.control.usedChannels = [usedChannels{:}];
end
    

