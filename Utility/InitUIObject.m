function handle = InitUIObject(varargin)
% Creates an object in the wc.module.handle scheme, and passes
% back the handle of the object.
% handle = InitUIObject(module, tag, creation_string, [properties])
%
%   module - the module in wc
%   tag - the name used to refer to the object
%   creation_string - an evalable string that generates the object
%   properties - optional comma-delim used to set some nice properties
%
%   $Id$
global wc

if nargin < 3
    handle = [];
    return;
end
module = varargin{1};
tag = varargin{2};
creation_string = varargin{3};

module = lower(module);

h = eval(creation_string, []);
if ishandle(h)
   
    set(h,'tag',tag);
    if nargin > 3
        set(h, varargin{4:nargin});
    end
    sfp = sprintf('wc.%s.handles.%s=h;',module,tag);
    eval(sfp);
end

handle = h;