function varargout = SweepAcquired(obj, event, callback)
% The SweepAcquired function is called when a sweep has acquired.
% It extracts the data from the engine and returns it via the
% callback.
%
%   void SweepAcquired(obj, event, callback)
%   obj - the data acquisition object (ai)
%   event - event data
%   callback - the function to be called.
%
%   The signature for the callback function is callback('sweep',data,time)
%
%   Telegraphs for the axoclamp 200B
% 
%   Gain:
%   0.5 - 2 V
%   1   - 2.5 V
%   etc (0.5 V steps)
%   500 - 6.5 V
% 
%   Mode:
%   Track - 4 V
%   VClamp - 6 V
%   I=0    - 3 V
%   IClamp - 2 V
%   Fast Ic - 1 V
%
% $Id$
global wc

samples = length(wc.control.pulse);
s = get(wc.ai,'SamplesAvailable');
if (s < samples)
    samples = s;
end
[data, time] = getdata(wc.ai, samples); % extract data
% I would prefer to use peekdata to determine the gain setting
% but since this call is incompatible with ManualTriggerHwOn
% there will be a delay of 1 sweep after the telegraph
% takes effect
% Furthermore, it may take too many cycles to do this computation
% every sweep, in which case...

if (isfield(wc.control.telegraph,'gain'))
    gainChannel = wc.control.telegraph.gain;
    gainVoltage = mean(data(:,gainChannel));
    gain = gain(gainVoltage);
    ChannelGain(wc.control.amplifier,'set',gain);
%     ir = get(wc.control.amplifier, 'SensorRange');
%     set(wc.control.amplifier,'UnitsRange',ir ./ gain);
end

if (isfield(wc.control.telegraph,'mode'))
    modeChannel = wc.control.telegraph.mode;
    modeVoltage = mean(data(:,modeVoltage));
    mode = mode(modeVoltage);
    set(wc.control.amplifier,'Units',units(mode));
end

feval(callback,'sweep',data,time);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function out = gain(gainVoltage)
% this function is basically just a lookup table
% but to figure out the best voltage value we have to do some rounding
try
    V = fix(gainVoltage(1) .* 2);
    gains = [0.5 1 2 5 10 20 50 100 200 500];
    voltages = 4:13; % doubled voltages
    i = find(voltages == V);
    out = gains(i);
catch
    out = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = mode(modeVoltage)

try
    V = fix(modeVoltage);
    modes = {'Fast Iclamp', 'IClamp', 'I=0', 'Track', 'VClamp'};
    voltages = [1 2 3 4 6];
    out = modes{find(voltages == V)};
catch
    out = 'Unknown';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = units(mode)
%returns the units appropriate to the given mode
switch mode
case {'Fast Iclamp', 'IClamp', 'I=0'}
    out = 'mV';
case {'VClamp', 'Track'}
    out = 'nA';
otherwise
    out = 'V';
end
    
    
    