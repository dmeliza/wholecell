function varargout = StartAcquisition(module, devices)
% starts data acquisition and keeps track of some variables useful
% to other modules
%
% void StartAcquisition(module, {devices})
%
% $Id$
global wc

stop(devices);
flushdata(wc.ai); % can we make this more general? only works with ainputs
wc.control.protocol = module;
start(devices);
trigger(devices);
SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
