function [] = ProcessResponse(signals)
%
% ProcessResponse is a GUI for filtering intracellular response data. Often
% a significant amount of post-processing is necessary to analyze these
% responses.  This function allows users to process one or more signals
% through a variety of filters.
%
% highpass filters - removing baseline and baseline drift
% lowpass filters - removing high frequency noise and fast artifacts
% event filters   - reduces a voltage or current trace to a sequence
%                   of events, or alternatively, removes events from
%                   the signal (e.g. spikes)
%
% [] = ProcessResponse(signals)
%
% signals - an r1 structure [array]
%
% zooming is linked between axes
%
% $Id$

error(nargchk(0,1,nargin))

filters = {'highpass','bandpass','lowpass','bin','framebin','spikes'};

initFigure;
initValues(filters);
% loadSignals(signals);

function [] = initFigure()
% creates the figure window and populates it with GUI objects
cb = getCallbacks;
BG = [1 1 1];
f = OpenFigure(me,'position',[360   343   700   600],...
    'color',BG,'menubar','none');
movegui(f,'northwest')

% first axes - raw signals
h  = InitUIObject(me, 'input', 'axes', 'units','pixels','position',[50 400 620 180],...
    'nextplot','replacechildren','Box','On');%,'XTick',[],'Ytick',[],'Box','On');
% second axes - processed signals
h  = InitUIObject(me, 'input', 'axes', 'units','pixels','position',[50 50 620 180],...
    'nextplot','replacechildren','Box','On');
% control frame
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[50 250 620 120]);
h = uicontrol(gcf, 'style', 'text', 'position',[60 350 120 15],'String','Filters',...
    'backgroundcolor',BG);
h = InitUIControl(me, 'filters', 'style','list',...
    'position', [60 260 120 90],'backgroundcolor',BG);
h = InitUIControl(me, 'addfilter', 'style', 'pushbutton', 'position', [190 310 50 25],...
    'String','-->', 'callback', cb.addfilter);
h = InitUIControl(me, 'removefilter', 'style', 'pushbutton', 'position', [190 280 50 25],...
    'String','<--', 'callback', cb.removefilter);
h = uicontrol(gcf, 'style', 'text', 'position',[250 350 120 15],'String','Active Filters',...
    'backgroundcolor',BG);
h = InitUIControl(me, 'activefilters', 'style','list',...
    'position', [250 260 120 90],'backgroundcolor',BG, 'callback', cb.activefilters);
h = InitUIControl(me, 'filterup', 'style', 'pushbutton', 'position', [380 310 25 25],...
    'String','up', 'callback', cb.filterup);
h = InitUIControl(me, 'filterdown', 'style', 'pushbutton', 'position', [380 280 25 25],...
    'String','dn', 'callback', cb.filterdown);
% filter description field
h = InitUIControl(me,'filterdesc','style','text','backgroundcolor',BG,...
    'position', [420 260 160 100], 'HorizontalAlignment', 'left', 'String', '');
% buttons
h = InitUIControl(me, 'loadchain', 'style', 'pushbutton', 'position', [590 325 70 25],...
    'String','Load Filters','callback',cb.loadchain);
h = InitUIControl(me, 'savechain', 'style', 'pushbutton', 'position', [590 295 70 25],...
    'String','Save Filters','callback',cb.savechain);
h = InitUIControl(me, 'savesignal', 'style', 'pushbutton', 'position', [590 265 70 25],...
    'String', 'Save Signal', 'callback', cb.savesignal);

function [] = initValues(filters)
% initializes the lists to their default values
SetUIParam(me,'filters','String',filters);

function param = getParameters(filtername, parameters)
% runs a dialog to allow the user to select parameters for the filter

function desc = getFilterDescription(filtername, parameters)
% returns a friendly string description of the filter's effects
desc = filtername;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:
%
function [] = addfilter(obj, event)
sel = GetUIParam(me,'filters','selected');
val = GetUIParam(me,'activefilters','String');
par = GetUIParam(me,'activefilters','UserData');
param   = getParameters(sel);
if isempty(val)
    val = {sel};
    par = {param};
else
    val = {val{:},sel};
    par = {par{:},param};
end
SetUIParam(me,'activefilters','String',val);
SetUIParam(me,'activefilters','UserData',par);
SetUIParam(me,'activefilters','Value',length(val));
desc = getFilterDescription(sel,param);
SetUIParam(me,'filterdesc','String',desc);

function [] = removefilter(obj, event)
% removes a filter and associated parameters from the active list
str = GetUIParam(me,'activefilters','String');
par = GetUIParam(me,'activefilters','UserData');
if ~isempty(str)
    sel = GetUIParam(me,'activefilters','Value');
    i   = setdiff(1:length(str),sel);
    str = str(i);
    SetUIParam(me,'activefilters','String',str);
    SetUIParam(me,'activefilters','UserData',par(i));
    SetUIParam(me,'activefilters','Value',length(str));
end

function [] = activefilters(obj, event)
% allows the user to edit the parameters for the filter with a double-click
% for single clicks, displays a summary of the settings in a text box
click = get(gcf,'SelectionType');
switch lower(click)
case 'open'
    % double click
otherwise
    str   = GetUIParam(me,'activefilters','String');
    par   = GetUIParam(me,'activefilters','UserData');
    if ~isempty(str)
        sel = GetUIParam(me,'activefilters','Value');
        desc = getFilterDescription(str{sel},par{sel});
        SetUIParam(me,'filterdesc','String',desc);
    end
end

function [] = filterup(obj, event)
% moves the selected item up one spot
str = GetUIParam(me,'activefilters','String');
par = GetUIParam(me,'activefilters','UserData');
if ~isempty(str)
    sel = GetUIParam(me,'activefilters','Value');
    if sel > 1
        i = [1:sel-2, sel, sel-1, sel+1:length(str)];
        SetUIParam(me,'activefilters','String',str(i));
        SetUIParam(me,'activefilters','UserData',par(i));
        SetUIparam(me,'activefilters','Value',sel-1);
    end
end

function [] = filterdown(obj, event)
% moves the selected item down one spot
str = GetUIParam(me,'activefilters','String');
par = GetUIParam(me,'activefilters','UserData');
if ~isempty(str)
    sel = GetUIParam(me,'activefilters','Value');
    if sel < length(str)
        i = [1:sel-1, sel+1, sel, sel+2:length(str)];
        SetUIParam(me,'activefilters','String',str(i));
        SetUIParam(me,'activefilters','String',par(i));
        SetUIparam(me,'activefilters','Value',sel+1);
    end
end

function [] = loadchain(obj, event)
[fn pn] = uigetfile('*.mat');
if ~isnumeric(fn)
    d = load(fullfile(pn,fn));
    if isfield(d,'filters') & isfield(d,'parameters')
        SetUIParam(me,'activefilters','String',d.filters);
        SetUIParam(me,'activefilters','UserData',d.parameters);
        SetUIParam(me,'activefilters','Value',length(d.filters));
    end
end

function [] = savechain(obj, event)
[fn pn] = uiputfile('*.mat');
if ~isnumeric(fn)
    filters = GetUIParam(me,'activefilters','String');
    parameters = GetUIParam(me,'activefilters','UserData');
    save(fullfile(pn,fn),'filters','parameters');
end

function [] = savesignal(obj, event)

function out = getCallbacks()
% returns a structure with function handles to functions in this mfile
% no introspection in matlab so we have to do this by hand
fns = {'addfilter','removefilter','activefilters','filterup','filterdown', 'savechain',...
        'savesignal','loadchain'};
out = [];
for i = 1:length(fns)
    sf = sprintf('out.%s = @%s;',fns{i},fns{i});
    eval(sf);
end

function out = me()
out = mfilename;