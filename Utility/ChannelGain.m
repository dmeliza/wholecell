function gain = ChannelGain(channel, action, varargin)
% Converts between Matlab's engineering convention and a simple
% gain scalar
% gain = ChannelGain(channel, action, [gain])
% channel - the channel to get/set gain on
% action - 'get' or 'set'
% gain - required for 'set'.  this is Units/Volt; for example
%        if at 1 V the amp read 20 mV, set to 20
%
% $Id$

daq = channel.Parent;
type = daq.Type;

switch action
case 'get'
    fn = 'getGain';
case 'set'
    fn = 'setGain';
otherwise
    fn = 'err';
end

switch type
case 'Analog Input'
    gain = feval(fn, channel, channel.SensorRange, channel.UnitsRange, varargin);
case 'Analog Output'
    gain = feval(fn, channel, channel.OutputRange, channel.UnitsRange, varargin);
otherwise
    gain = err;
end

%%%%%%%%%%%%%%%%%%%%%%%
function gain = getGain(channel, inRange, outRange, gain)
% determines the gain
g = outRange ./ inRange;
gain = g(1);

%%%%%%%%%%%%%%%%%%%%%%%%
function gain = setGain(channel, inRange, outRange, gain)
% sets the gain. InRange is sacred, we don't touch that
if (length(gain) > 0)
    g = gain{1};
    gain = setverify(channel,'UnitsRange',inRange * g);
else
    gain = err;
end

%%%%%%%%%%%%%%%%%%%%%%
function out = err(varargin)

disp('Unsupported operation');
out = 0;

    