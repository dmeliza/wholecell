function PrePostAnalysis(varargin)
% Module for analyzing EPSP/C shape before and after an induction protocol

% $Id$

global wc


if nargin > 0
	action = lower(varargin{1});
else
	action = 'standalone';
end
switch action
    
case 'standalone'
    
    InitWC;
    fig = OpenGuideFigure(me,me,'DoubleBuffer','off');
    setupFigure(fig);

case 'init'
    fig = OpenGuideFigure(me,me,'DoubleBuffer','off');
    setupFigure(fig);
    
    
case {'pre_list_callback', 'post_list_callback'}
    recalcStats;
    
case {'pre_add_callback', 'post_add_callback'}
    addExperiment(action);
    
case {'pre_edit_callback', 'post_edit_callback'}
    editExperiment(action);
    
case {'pre_remove_callback', 'post_remove_callback'}
    removeExperiment(action);
    
case {'analysis1_callback', 'analysis2_callback', 'analysis3_callback'}
    setAnalysis(action);
    
case 'close_callback'
    delete(gcbf);
    
otherwise
    
    disp(['No such action ' action]);
    
end

%%%%%%%%%%%%%%%%%%%%
function m = me()
m = mfilename;

%%%%%%%%%%%%%%%%%%%%
function setupFigure(fig)
% initializes the figure

m = uimenu(fig,'Label','&File');
h = uimenu(m, 'Label', '&Load', 'Callback', [me '(''load_file_Callback'')']);
h = uimenu(m, 'Label', '&Save', 'Callback', [me '(''save_file_Callback'')']);
h = uimenu(m, 'Label', 'E&xit', 'Callback', [me '(''close_Callback'')'],...
    'separator','on');
pl = GetUIHandle(me,'pre_list');
ppl = GetUIHandle(me,'post_list');
set([pl ppl],'String',{},'UserData',[]);

registerModule({'pspdata','irdata','srdata'});

%%%%%%%%%%%%%%%%%%%%%5
function recalcStats()

%%%%%%%%%%%%%%%%%%%%%%
function setAnalysis(action)
prefix = 'analysis';
num = action(length(prefix)+1);
sel = GetUIParam(me, ['analysis' num], 'selected');
switch sel
case 'no analysis'
    clearPanel(num);
otherwise
    setupPanel(num, sel);
end

%%%%%%%%%%%%%%%%%%%%%%
function addExperiment(action)
% loads an experiment into the appropriate list (pre or post)
curdir = GetUIParam(me,'pre_add','UserData');
[fn pn] = uigetfile([curdir '*.mat'],'Choose an experiment file...');
if fn == 0
    return
end
pnfn = fullfile(pn, fn);
if exist(pnfn,'file') == 0
    return
end
SetUIParam(me,'pre_add','UserData',pn);
d = load(pnfn);
s = describe(fn, d);
if isempty(s)
    return
end
type = action(1:4);
if strmatch('post',type)
    list = GetUIHandle(me,'post_list');
else
    list = GetUIHandle(me,'pre_list');
end
ds = get(list,'UserData');
ls = get(list,'String');
ds{length(ds)+1} = d;
ls{length(ls)+1} = s;
set(list,'UserData',ds,'String',ls,'Value',[],'Max',2);
recalcStats;

function removeExperiment(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% removes an experiment from the list
type = action(1:4);
if strmatch('post',type)
    list = GetUIHandle(me,'post_list');
else
    list = GetUIHandle(me,'pre_list');
end
ds = get(list,'UserData');
ls = get(list,'String');
sel = get(list,'Value');
ind = 1:length(ls);
new = setdiff(ind,sel);
set(list,'UserData',ds(new),'String',ls(new),'Value',[]);

function editExperiment(action)
% does nothing now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = clearPanel(num)
% clears out the contents of a panel
tag = ['analysis' num '_frame'];
p = GetUIHandle(me, tag);
k = get(p,'UserData');
delete(k);

function setupPanel(num, analysis_module)
% Installs an analysis module in a panel. panel.UserData holds the panel's
% children
p = clearPanel(num);
k = feval(analysis_module, 'install');
set(p, 'UserData', k);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function registerModule(modules)
% installs modules in the module list
a1 = GetUIHandle(me,'analysis1');
curr = get(a1,'String');
if ~isa(curr,'cell')
    curr = cellstr(curr);
end
if isa(modules,'cell')
    new = {curr{:},modules{:}};
else
    new = {curr{:},modules};
end
a2 = GetUIHandle(me,'analysis2');
a3 = GetUIHandle(me,'analysis3');
set([a1 a2 a3],'String', new);


%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = describe(filename, d)
% produces a one-line string to describe the data in an experiment
s = [];
if ~isfield(d,'info'),return,end;
try
    num = length(d.abstime);
    pspmean = mean(d.pspdata);
    srmean = mean(d.srdata);
    irmean = mean(d.irdata);
    
%     s = sprintf('%s(%d): %3.3g (%s/ms), %3.1f (MOhm), %3.1f (MOhm)',...
%         filename, num, pspmean, d.info.y_unit, srmean, irmean);
    s = sprintf('%s(%d)', filename, num);
catch
    disp(lasterr);
    errordlg({[filename ' is not an experiment file.']},'File format error.');
    return
end

