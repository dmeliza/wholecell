function handle = InitUIControl(module, tag, properties)
% Creates an uicontrol in the wc.module.handle scheme, and passes
% back the handle of the object.
% handle = InitUIControl(module, tag, [properties])
%
%   module - the module in wc
%   tag - the name used to refer to the object
%   properties - optional cell array used to set some nice properties
%                (e.g. {'color',[1 1 1],'doublebuffer','on',...})
%
%   $Id$
global wc

error(nargchk(2,3,nargin));

module = lower(module);
fig = findobj('tag',module);
if ~ishandle(fig)
    error('No such module figure exists');
end

if nargin > 2
    h = uicontrol(fig,properties{:});
else
    h = uicontrol(fig);
end

if ishandle(h)
    set(h,'tag',tag);
    sfp = sprintf('wc.%s.handles.%s=h;',module,tag);
    eval(sfp);
end

handle = h;