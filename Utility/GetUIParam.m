function out = GetUIParam(module, param, field)
% Accesses the contents of a GUI object
% out = GetUIParam(module, param, format)
%
%   module - the module in wc
%   param - the tag for the GUI object
%
%   $Id$
global wc

%param = lower(param);
module = lower(module);

% find out if the object exists
sfp = sprintf('isfield(wc.%s.handles,''%s'')',module,param);
if (eval(sfp))
    sf = sprintf('wc.%s.handles.%s', module, param);
    switch field
    case {'StringVal','stringval','Stringval'}
        out = str2num(get(eval(sf),'String'));
    case {'Selected','selected'}
        i = get(eval(sf),'Value');
        s = get(eval(sf),'String');
        if i <= length(s)
            out = s(i,:);
        else
            out = s;
        end
    otherwise    
        out = get(eval(sf), field);
    end
else
    out = [];
    disp(['no such field ' param ' in module ' module]);
end
    