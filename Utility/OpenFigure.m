function fig = OpenFigure(module,varargin)
% Opens a blank figure window 
% void OpenFigure(module,[prop1,val1],[prop2,val2],[...])
% sets properties to values if supplied
global wc

obj.fig = figure('numbertitle','off','name',module,'tag',module,...
             'DoubleBuffer','on','menubar','none');
set(obj.fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
obj.handles = guihandles(obj.fig);
guidata(obj.fig, obj.handles);
if nargin > 2
    set(obj.fig, varargin{:});
end
sf = sprintf('wc.%s = obj;',module);
eval(sf);
fig = obj.fig;
