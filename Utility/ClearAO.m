function ClearAO(obj, event)
% stops and clears the state of an analog output object. Conforms
% to the callback stub (obj,event) so that it can be set as an action
% on an input or output object.
%
% Usage: [] = ClearAO(obj,[event])
%
% obj - an analogoutput object
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
    % this code would send a zero to all outputs, but is unimplemented
    c = get(obj,'Channel');
    putsample(obj,zeros(1,length(c)));
end