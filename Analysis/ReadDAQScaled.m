function [data, time, abstime] = ReadDAQScaled(filename, datachannel, gc, units)
% adjusts the scale of the data based on telegraph info in the gain channel
%
% $Id$
[dat, time, abstime] = daqread(filename,'Channel',[datachannel gc]);
gain = 1 / TelegraphReader('gain',mean(dat(:,2)));
switch units
case {'mV','pA'}
    gain = gain * 1000;
end
data = dat(:,1) * gain;