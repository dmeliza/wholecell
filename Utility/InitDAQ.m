function out = InitDAQ(sampleRate)
% Initializes the first data acquisition hardware found in the system
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
wc.control.channels = a.SingleEndedIDs;
wc.control.usedChannels = [];

% set some basic values
a = setverify(wc.ai,'InputType','SingleEnded');
wc.control.Coupling = a;
a = setverify([wc.ai wc.ao],'SampleRate', sampleRate);
wc.control.SampleRate = a{1};

% set up triggering for simultaneous use
set([wc.ai wc.ao], 'TriggerType', 'Manual');
% this is problematic.  I can't use peekdata if this is on,
% but the synchronization of input and output is off by at
% least 20 ms if I don't use it.  It's not a big deal for
% SealTest, but it will be for STDP stuff.
set(wc.ai, 'ManualTriggerHwOn', 'Trigger');
