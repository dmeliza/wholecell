function [] = InitDAQ(sampleRate)
% Initializes the first data acquisition hardware found in the system, creating
% the analoginput, analogoutput, and digitalio objects.
% This is horribly inflexible, but I don't anticipate using two nidaq boards
% (or anything other than nidaq boards) for some time to come.
%
% Usage:  [] = InitDAQ(sampleRate)
%
% sampleRate - the sample rate, in Hz, of the analog input and output objects.
%
% $Id$
global wc

daqreset;
a = daqhwinfo;
adaptor = a.InstalledAdaptors{1}; % this should be the nidaq
a = daqhwinfo(adaptor);
on = a.ObjectConstructorName;
wc.ai = eval(on{1});
wc.ao = eval(on{2});
wc.dio = eval(on{3});

% get information about the daq
a = daqhwinfo(wc.ai);
wc.control.DeviceName = a.DeviceName;
wc.control.AdaptorName = a.AdaptorName;
wc.control.TotalChannels = a.TotalChannels;
wc.control.ai.channels = a.SingleEndedIDs;
wc.control.ai.usedChannels = [];
a = daqhwinfo(wc.ao);
wc.control.ao.channels = a.ChannelIDs;
wc.control.ao.usedChannels = [];

% set some basic values
a = setverify(wc.ai,'InputType','SingleEnded');
wc.control.Coupling = a;
a = setverify([wc.ai wc.ao],'SampleRate', sampleRate);
wc.control.SampleRate = a{1};
