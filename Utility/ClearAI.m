function ClearAI(obj, event)
% stops, and clears the state of an analog input object
%
% $Id$
if isvalid(obj)
    set(obj,'StopAction','daqaction');
    stop(obj);
    set(obj,'SamplesAcquiredAction',{});
    set(obj,'TimerAction',{});
    set(obj,'StartAction','daqaction');
    set(obj,'TriggerAction',{});
    set(obj,'LoggingMode','Memory');
    set(obj,'LogFileName',NextDataFile);
    set(obj,'TriggerType','Manual');
    set(obj,'ManualTriggerHwOn','Trigger');
end