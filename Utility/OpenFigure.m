function fig = OpenFigure(module,varargin)
% Opens a blank figure window, or if a figure with that handle already exists,
% returns the handle to it.
%
% Usage: handle =  OpenFigure(module,[prop1,val1],[prop2,val2],[...])
%
% module - the name of the module (used for the tag and for the wc structure)
% propn  - property name
% valn   - the corresponding value
%
% $Id$
global wc

% open or find the figure
module  = lower(module);
obj.fig = findfig(module);
% set some default values
set(obj.fig, 'numbertitle','off','name',module,'DoubleBuffer','on','menubar','none');
set(obj.fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
obj.handles = guihandles(obj.fig);
guidata(obj.fig, obj.handles);
if nargin > 2
    set(obj.fig, varargin{:});
end
sf = sprintf('wc.%s = obj;',module);
eval(sf);
fig = obj.fig;
