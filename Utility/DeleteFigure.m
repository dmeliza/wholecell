function varargout = DeleteFigure(figname);
% Cleans up a figure's properties from the wc object
% and deletes it.
% figname - the name of the figure
%
% $Id$

global wc

disp(['Closing figure ' figname]);
if isfield(wc, figname)
    wc = rmfield(wc, figname);
end
obj = findobj('tag', figname);
%delete(obj(find(ishandle(obj))));
delete(gcbf);