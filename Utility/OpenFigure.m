function fig = OpenFigure(module,varargin)
% Opens a blank figure window 
% void OpenFigure(module,[{properties},{values}])
% sets {properties} to {values} if supplied
global wc

clfcn = sprintf('%s(''close_Callback'');',module);
obj.fig = figure('numbertitle','off','name',module,'tag',module,...
             'DoubleBuffer','on','menubar','none','closerequestfcn',clfcn);
set(obj.fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
obj.handles = guihandles(obj.fig);
guidata(obj.fig, obj.handles);
if nargin > 2
    properties = varargin{1};
    values = varargin{2};
    set(obj.fig, properties, values);
end

sf = sprintf('wc.%s = obj;',module);
eval(sf);
fig = obj.fig;
