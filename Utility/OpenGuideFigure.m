function fig = OpenGuideFigure(module, varargin)
% Opens a figure window using a GUIDE-generated .fig file
% void OpenGuideFigure(module,[tag])
% opens a figure with the filename module.fig
% if tag is supplied the figure will be tagged as such (and stored in wc
% under that tag)
%
% $Id$
global wc


if nargin > 1
    tag = lower(varargin{1});
else
    tag = lower(module);
end

obj.fig = findobj('tag', tag);
if isempty(obj.fig) | ~ishandle(obj.fig)
    obj.fig = openfig(module, 'reuse');
end
set(obj.fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
obj.handles = guihandles(obj.fig);
guidata(obj.fig, obj.handles);
clfcn = sprintf('%s(''close_Callback'', ''%s'')', module, tag);
set(obj.fig, 'numbertitle', 'off', 'name', tag, 'tag', tag,...
             'DoubleBuffer','on','menubar','none','closerequestfcn',clfcn);

sf = sprintf('wc.%s = obj;', tag);
eval(sf);
fig = obj.fig;
