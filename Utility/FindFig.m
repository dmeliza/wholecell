function handle = FindFig(tag)
%
% Opens a figure window with a given tag.  Or if one already exists,
% sets it as current and returns the handle.
%
% Usage:  handle = FindFig(tag)
%
% tag - a string that matches the figure's tag (or will be the new figure's tag)
%
% handle - the matlab GUI handle that identifies the figure
%
% $Id$

error(nargchk(1,1,nargin))

handle      = findobj('tag',tag,'type','figure');
if ishandle(handle)
    figure(handle);
else
    handle  = figure;
    set(gcf, 'tag', tag);
end