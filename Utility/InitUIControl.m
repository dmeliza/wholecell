function handle = InitUIControl(module, tag, varargin)
% Creates an uicontrol in the wc.module.handle scheme, and passes
% back the handle of the object.
% handle = InitUIControl(module, tag, [properties])
%
%   module - the module in wc
%   tag - the name used to refer to the object
%   properties - optional cell array used to set some nice properties
%                (e.g. {'color',[1 1 1],'doublebuffer','on',...})
%                or a comma-delimited list
%
%   $Id$
global wc

if nargin < 2
    error('Usage: InitUIControl(module, tag, properties,...)');
end

module = lower(module);
fig = findobj('tag',module);
if ~ishandle(fig)
    error('No such module figure exists');
elseif length(fig) > 1
    error('Too many figures open with that tag');
end

if nargin == 3
    h = uicontrol(fig,varargin{1}{:});
elseif nargin >= 4
    h = uicontrol(fig,varargin{:});
else
    h = uicontrol(fig);
end

if ishandle(h)
    set(h,'tag',tag);
    sfp = sprintf('wc.%s.handles.%s=h;',module,tag);
    eval(sfp);
end

handle = h;