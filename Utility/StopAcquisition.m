function varargout = StopAcquisition(module, devices)
% starts data acquisition and keeps track of some variables useful
% to other modules
%
% void StartAcquisition(module, {devices})
%
% $Id$
global wc

if (isvalid(devices))
stop(devices);
end
if (isvalid(wc.ai))
    set(wc.ai,'SamplesAcquiredAction','');
    wc.control.protocol = [];
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
end
