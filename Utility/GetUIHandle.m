function handle = GetUIHandle(module, object_name)
% Accesses a gui object using its tag
% handle = GetUIParam(module, object_name)
%
%   module - the module in wc
%   param - the tag for the GUI object
%
%   $Id$
global wc

module = lower(module);

% find out if the object exists
sfp = sprintf('isfield(wc.%s.handles,''%s'')',module,object_name);
if (eval(sfp))
    sf = sprintf('wc.%s.handles.%s', module, object_name);
    handle = eval(sf);
else
    out = [];
    disp(['no such field ' param ' in module ' module]);
end
    
