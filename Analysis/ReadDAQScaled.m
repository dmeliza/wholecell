function [data, units] = ReadDAQScaled(dat, datachannel,...
                                               gc, mc, defaultunits)
% adjusts the scale of the data based on telegraph info in the gain channel
% and the mode of the amplifier
%
% $Id$

if isempty(mc)
    units = defaultunits;
else
    units = TelegraphReader('units',mean(dat(:,mc)));
end
if isempty(gc)
    data = dat;
else
    gain = TelegraphReader('gain',mean(dat(:,gc)));
    data = AutoGain(dat(:,datachannel), gain, units);
end
