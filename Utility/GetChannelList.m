function out = GetChannelList(daqdevice)
% returns a cell array of pretty-printed information about
% channels in a daqdevice.
%
% USAGE: out = GetChannelList(daqdevice)
%
% daqdevice     - a daqdevice object (with the Channel property)
% out           - a cell array of strings describing the channels in the daqdevice
%
% $Id$
%

out = '';
c = get(daqdevice.Channel,{'HwChannel','ChannelName','Units'});
for i=1:size(c,1);
    out{i} = sprintf('%i: %s (%s)', c{i,1}, c{i,2}, c{i,3});
end
