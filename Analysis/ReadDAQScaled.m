function [data, time, abstime, units] = ReadDAQScaled(filename, info)
% ReadDAQScaled:
% 
% [DATA, TIME, ABSTIME, INFO] = ReadDAQScaled(FILENAME, INFO)
% Reads a DAQ file from disk.  Using the INFO structure (which is returned by
% daqread(filname,'info')), an attempt will be made to scale 
% the data based on telegraph info in the gain channel and mode channels
%
% FILENAME must exist, otherwise the underlying daqread function will throw
% an error.
%
% $Id$

error(nargchk(2,2,nargin))

[data, time, abstime]       = daqread(filename);
units                       = {info.channels.Units};
if isfield(info, 'amp')
    dc  = info.amp;
    if isfield(info, 'mode')
        mc                  = info.mode;
        units{dc}           = TelegraphReader('units',mean(data(:,mc)));
    end
    if strcmpi(units{dc},'na')
        units{dc} = 'pA';       % personal preference, comment this out if you prefer nA
    end
    if isfield(info, 'gain')
        gc                  = info.gain;
        gain                = TelegraphReader('gain',mean(data(:,gc)));
        data(:,dc)          = AutoGain(data(:,dc), gain, units{dc});
    end
end
