function handle = GetUIHandle(module, object_name)
% Accesses a gui object using its tag
% handle = GetUIParam(module, object_name)
%
%   module - the module in wc
%   param - the tag for the GUI object
%   if a cell array is supplied for object_name, a vector of handles is returned
%
%   $Id$
global wc

if iscell(object_name)
    for i = 1:length(object_name)
        handle(i) = GetUIHandle(module, object_name{i});
    end
else

    module = lower(module);
    
    % find out if the module exists
    if (~isfield(wc,module))
        handle = [];
        return;
    end
    % find out if the object exists
    sfp = sprintf('isfield(wc.%s.handles,''%s'')',module,object_name);
    if (eval(sfp))
        sf = sprintf('wc.%s.handles.%s', module, object_name);
        handle = eval(sf);
    else
        out = [];
        disp(['no such object ' param ' in module ' module]);
    end
end
    
