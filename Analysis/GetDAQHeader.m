function [info, str] = GetDAQHeader(filename)
% Retrieves header information from a daq file.
%
% Usage: info = GetDAQHeader(filename)
%
% filename      -   The input file name
% 
% info          -   The output structure, which contains the following fields:
%
%                   .t_unit     -   the time unit
%                   .t_rate     -   sampling rate
%                   .start_time -   the start time (clock vector)
%                   .samples    -   the number of samples
%                   .channels   -   structure array of channel properties
%                   .amp        -   index of amplifier channel (if there is one)
%                   .mode       -   index of mode telegraph channel (if there is one)
%                   .gain       -   index of gain telegraph channel (if there is one)
%
%   1.2: Generate friendly string description, catch unreadable files
%
%   $Id$
info = [];
str  = '';
try
    d = daqread(filename,'info');
catch
    str = [filename ': Invalid DAQ file'];
    return
end
info.t_unit = 's';
info.t_rate = d.ObjInfo.SampleRate;
info.start_time = d.ObjInfo.InitialTriggerTime;
info.samples = d.ObjInfo.SamplesAcquired;
info.channels = d.ObjInfo.Channel;
cnames = {info.channels.ChannelName};
info.amp = strmatch('amplifier',cnames);
info.mode = strmatch('mode',cnames);
info.gain = strmatch('gain',cnames);

% make sure there is an amp channel
if isempty(info.amp)
    info.amp = 1;
end

str = sprintf('%s: %d channels, %d samples',filename,length(cnames),info.samples);