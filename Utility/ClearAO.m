function ClearAO(obj, event)
% clears the state of an analog output object
%
% $Id$
if isvalid(obj)
    set(obj,'StopAction',{});
    stop(obj);
    c = get(obj,'Channel');
    putdata(obj,zeros(length(c)));
    set(obj,'RepeatOutput',1);
    start(obj);
    trigger(obj);
end