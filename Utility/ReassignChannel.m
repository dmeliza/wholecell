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
type = daq.Type;
switch type
case 'Analog Output'
    sf = 'wc.control.ao.usedChannels';
case 'Analog Input'
    sf = 'wc.control.ai.usedChannels';
otherwise
    sf = 'wc.control.ai.usedChannels';
end

usedChannels = daq.Channel.HwChannel;
if (length(usedChannels) == 1)
    eval([sf '= usedChannels;']);
else
    eval([sf '= [usedChannels{:}];']);
end
    

