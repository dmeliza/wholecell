function ClearAO(obj, event)
% clears the state of an analog output object
%
% $Id$
if isvalid(obj)
    set(obj,'StopAction',{});
    set(obj,'RepeatOutput',0);
    stop(obj);
    c = get(obj,'Channel');
    putsample(obj,zeros(1,length(c)));
%     putdata(obj,zeros(length(c)));
%     start(obj);
%     trigger(obj);
end