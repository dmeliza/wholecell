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
if (length(usedChannels) == 1)
    wc.control.usedChannels = usedChannels;
else
    wc.control.usedChannels = [usedChannels{:}];
end
    

