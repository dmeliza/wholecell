function ClearAO(obj, event)
% stops and clears the state of an analog output object
%
% $Id$
if isvalid(obj)
    set(obj,'StopAction','daqaction');
    stop(obj);
    set(obj,'RepeatOutput',0);
    set(obj,'SamplesOutputAction',{});
    set(obj,'TimerAction',{});
    set(obj,'StartAction','daqaction');
    set(obj,'TriggerAction',{});
    set(obj,'TriggerType','Manual');
%    c = get(obj,'Channel');
%    putsample(obj,zeros(1,length(c)));
%     putdata(obj,zeros(length(c)));
%     start(obj);
%     trigger(obj);
end