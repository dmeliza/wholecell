function out = GetChannelList(daqdevice)
% returns a cell array of pretty-printed information about
% channels in a daqdevice
out = '';
c = get(daqdevice.Channel,{'HwChannel','ChannelName','Units'});
for i=1:size(c,1);
    out{i} = sprintf('%i: %s (%s)', c{i,1}, c{i,2}, c{i,3});
end
