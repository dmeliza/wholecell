function varargout = SweepAcquired(obj, event, callback)
% The SweepAcquired function is called when a sweep has acquired.
% It extracts the data from the engine and returns it via the
% callback.
% OBJ - the data output object (not used)
% EVENT - event data
% CALLBACK - the callback function
% $Id$

global wc

[data, time] = getdata(wc.ai,length(wc.command)); % extract data
feval(callback,'sweep',data,time);

