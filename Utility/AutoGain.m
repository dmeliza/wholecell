function data = AutoGain(data, gain, units)
% scales a data set according to the gain (on the amplifier) and the final
% units
%
% $Id$
gain = 1 / gain;
switch units
case {'mV','pA'}
    gain = gain * 1000;
end
data = data(:,1) * gain;