function [data, time, abstime] = ReadDAQScaled(filename, datachannel, gc, units)
% adjusts the scale of the data based on telegraph info in the gain channel
%
% $Id$
[dat, time, abstime] = daqread(filename,'Channel',[datachannel gc]);
gain = TelegraphReader('gain',mean(dat(:,2)));
data = AutoGain(dat(:,1), gain, units);
