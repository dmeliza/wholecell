function fig = OpenGuideFigure(module,varargin)
% Opens a figure window using a GUIDE-generated .fig file
% void OpenGuideFigure(module,[{properties},{values}])
% opens a figure with the filename module.fig
% sets {properties} to {values} if supplied
global wc


obj.fig = openfig(module, 'reuse');
set(obj.fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
obj.handles = guihandles(obj.fig);
guidata(obj.fig, obj.handles);
clfcn = sprintf('%s(''close_Callback'');',module);
set(obj.fig,'numbertitle','off','name',module,'tag',module,...
             'DoubleBuffer','on','menubar','none','closerequestfcn',clfcn);
if nargin > 2
    properties = varargin{1};
    values = varargin{2};
    set(obj.fig, properties, values);
end

sf = sprintf('wc.%s = obj;',module);
eval(sf);
fig = obj.fig;
