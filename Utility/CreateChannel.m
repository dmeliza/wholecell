function c = CreateChannel(daq, hwindex, varargin)
% adds a channel to the analog input or output system
% channel = CreateChannel(daq, hwindex, [{properties}, {values}])
%
% $Id$
global wc

c = addchannel(daq, hwindex);
if nargin > 3
    properties = varargin{1};
    values = varargin{2};
    set(c, properties, values);
end

usedChannels = daq.Channel.HwChannel;
type = daq.Type;
switch type
case 'Analog Output'
    sf = 'wc.control.ao.usedChannels';
case 'Analog Input'
    sf = 'wc.control.ai.usedChannels';
otherwise
    sf = 'wc.control.ai.usedChannels';
end

if (length(usedChannels) == 1)
    eval([sf '= usedChannels;']);
else
    eval([sf '= [usedChannels{:}];']);
end    

