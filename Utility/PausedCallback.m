function varargout = PausedCallback(varargin)
% A wrapper function used to insert a pause between a callback
% from a daq and the execution of some function in the
% calling module
%
% void PausedCallback(obj, event, callback_module, pause_time, [arguments])
%
% $Id$

disp(['pausing ' num2str(varargin{4}) ' seconds']);
pause(varargin{4});  % unfortunately it's not possible to arrest this mid-stroke
% to do: check to see if the protocol is still running
if (nargin > 4)
    feval(varargin{3}, varargin{5:nargin});
else
    feval(varargin{3});
end
