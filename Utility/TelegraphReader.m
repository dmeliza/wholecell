function out = TelegraphReader(telegraph, voltage)
% converts a voltage on a telegraph line into meaningful information
% 'telegraph' is a string that can take the following values: 'mode','units','gain'
% voltage is a scalar which is used to generate the output
% Additional telegraphs can be interpreted by writing a function in this file (or another)
% named for the telegraph name
%
% $Id$

if ischar(telegraph) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		out = feval(telegraph, voltage);
	catch
		disp(lasterr);
	end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function out = gain(gainVoltage)
% this function is basically just a lookup table
% but to figure out the best voltage value we have to do some rounding
try
    V = round(gainVoltage(1) .* 2);
    gains = [0.5 1 2 5 10 20 50 100 200 500];
    voltages = 4:13; % doubled voltages
    i = find(voltages == V);
    if (isempty(i))
        out = 1;
    else
        out = gains(i);
    end
catch
    out = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = mode(modeVoltage)

try
    V = round(modeVoltage);
    modes = {'Fast Iclamp', 'IClamp', 'I=0', 'Track', 'VClamp'};
    voltages = [1 2 3 4 6];
    i = find(voltages == V);
    if (isempty(i))
        out = 'Unknown';
    else
        out = modes{i};
    end
catch
    out = 'Unknown';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = units(modeVoltage)
%returns the units appropriate to the given mode
m = mode(modeVoltage);
switch m
case {'Fast Iclamp', 'IClamp', 'I=0'}
    out = 'mV';
case {'VClamp', 'Track'}
    out = 'nA';
otherwise
    out = 'V';
end