function handle = FindFig(tag)
%
% Opens a figure window with a given tag.  Or if one already exists,
% sets it as current and returns the handle
%
% $Id$

error(nargchk(1,1,nargin))

handle = findobj('tag',tag);
if ishandle(handle)
    figure(handle);
else
    handle = figure;
    set(gcf, 'tag', tag);
end