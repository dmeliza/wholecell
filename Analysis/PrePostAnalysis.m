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
    % synchronizes the selection content of the two lists
    synchlists(gcbo);
    recalcStats;
    
case {'pre_add_callback', 'post_add_callback'}
    addExperiment(action);
    
case {'pre_edit_callback', 'post_edit_callback'}
    editExperiment(action);
    
case {'pre_remove_callback', 'post_remove_callback'}
    removeExperiment(action);
    
case {'analysis1_callback', 'analysis2_callback', 'analysis3_callback'}
    setAnalysis(action);
    
case 'binsize_callback'
    recalcStats;
    
case 'normalization_callback'
    hit = gcbo;
    h(1) = GetUIHandle(me,'norm_none');
    h(2) = GetUIHandle(me,'norm_add');
    h(3) = GetUIHandle(me,'norm_mult');
    set(h,'UserData',get(hit,'tag'));
    set(h,'Value',0);
    set(hit,'Value',1);
    recalcStats;

case 'export_csv_callback'
    [fn, pn] = uiputfile('*.csv');
    if fn == 0
        return
    end
    data = [];
    norm = GetUIParam(me,'norm_none','UserData');
    [pre, post] = getData(norm);
    pre = calculateresting(pre);
    post = calculateresting(post);
    datatypes = {'pspdata','irdata','srdata','resting'};
    for i = 1:length(datatypes);
        ds = datatypes{i};
        bs = GetUIParam(me,'binsize','stringval');
        if ~isnumeric(bs)
            bs = 0.5;
        end
        [pre_data, pre_abstime, pre_err, pre_n] = aligndata(pre, 'pre',ds, bs);
        [post_data, post_abstime, post_err, post_n] = aligndata(post, 'post', ds, bs);
        if length(pre_n) > 1
            d = [pre_data, post_data; pre_err, post_err; pre_n post_n];
        else
            d = [pre_data, post_data];
        end
        data = cat(2,data,d');
    end
    t = [pre_abstime, post_abstime];
    data = cat(2,t',data);
    headers = {'time(min)',...
            'response','STD','n',...
            'IR','STD','n',...
            'SR','STD','n',...
            'resting','STD','n'};
    tblwrite(data, char(headers),'',fullfile(pn,fn),',');
    
case 'export_report_callback'
    [fn, pn] = uiputfile('*.csv');
    if fn == 0
        return
    end
    data = [];
    norm = GetUIParam(me,'norm_none','UserData');
    [pre, post] = getData(norm);
       
    
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
m = uimenu(fig,'Label','&Export');
h = uimenu(m, 'Label', '&Report', 'Callback', [me '(''export_report_Callback'')']);
h = uimenu(m, 'Label', '&CSV file', 'Callback', [me '(''export_csv_Callback'')']);
pl = GetUIHandle(me,'pre_list');
ppl = GetUIHandle(me,'post_list');
set([pl ppl],'String',{},'UserData',[]);
SetUIParam(me,'norm_none','UserData','norm_none');
SetUIParam(me,'norm_none','Value',1);


registerModule({'pspdata','irdata','srdata','psth','resting'});

%%%%%%%%%%%%%%%%%%%%%5
function recalcStats()
norm = GetUIParam(me,'norm_none','UserData');
[pre, post] = getData(norm);
if isempty(pre) & isempty(post)
    return
end
for p_num = 1:3
    sel = GetUIParam(me,['analysis' num2str(p_num)], 'selected');
    if ~strcmp(sel,'no analysis')
        feval(sel,'analyze', num2str(p_num), pre,post);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%5
function [pre,post] = getData(normalize)
% retrieves data from a list. The tricky thing here is that in some cases
% we want to normalize data in one list against the other. Thus, the function
% retrieves data from both lists at once.  It assumes that datasets with the
% same rank in each list are linked to one another. Parameter normalize
% can be {'norm_none'},'norm_add', or 'norm_mult'.
[pre,post] = private_getData;
fields = {'pspdata','srdata','irdata'};
switch normalize
case 'norm_add'
    op = '-';
case 'norm_mult'
    op = '/';
otherwise
    return
end
for i = 1:length(pre)
    for j = 1:length(fields)
        fr = sprintf('pre{i}.%s',fields{j});
        m(j) = mean(mean(eval(fr)));
        sf = sprintf('%s = %s %s m(j);',fr,fr,op);
        eval(sf);
        if i <= length(post)
            fr = sprintf('post{i}.%s',fields{j});
            sf = sprintf('%s = %s %s m(j);',fr,fr,op);
            eval(sf);
        end
    end
end
    

function [varargout] = private_getData;
% an internal function that retrieves the datasets associated with the
% selected items in the list
a = {'pre_list','post_list'};
for i = 1:length(a)
    num = GetUIParam(me,a{i},'value');
    ds = GetUIParam(me,a{i},'userdata');
    if ~isempty(num) & ~isempty(ds)
        varargout{i} = ds(num);
    else
        varargout{i} = [];
    end
end
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
    recalcStats;
end

%%%%%%%%%%%%%%%%%%%%%%%%%5
function synchlists(list)
% synchronizes the selections in the lists so that pre-post pairs
% stay paired
if strcmp(get(list,'tag'),'pre_list')
    other_list = GetUIHandle(me,'post_list');
else
    other_list = GetUIHandle(me,'pre_list');
end
sel = get(list,'value');
len = length(get(list,'string'));
other_sel = get(other_list,'value');
other_len = length(get(other_list,'string'));
if len > other_len
    i = find(sel <= other_len);
    other_sel = sel(i);
elseif len < other_len
    other_sel = [sel other_sel(find(other_sel > len))];
else
    other_sel = sel;
end
set(other_list,'value',other_sel);

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
d.pnfn = pnfn;
%d = calculateresting(d);
s = describe(fn, d);
if isempty(s)
    return
end
type = action(1:4);
if strcmp('post',type)
    list = GetUIHandle(me,'post_list');
else
    list = GetUIHandle(me,'pre_list');
end
ds = get(list,'UserData');
ls = get(list,'String');
ds{length(ds)+1} = d;
ls{length(ls)+1} = s;
set(list,'UserData',ds,'String',ls,'Value',[],'Max',2);
synchlists(list);
recalcStats;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function removeExperiment(action)
% removes an experiment from the list
type = action(1:4);
if strcmp('post',type)
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
tag = ['analysis' num];
p = GetUIHandle(me, tag);
k = get(p,'UserData');
delete(k(find(ishandle(k))));
set(p,'UIContextMenu',[]);

function setupPanel(num, analysis_module)
% Installs an analysis module in a panel. listbox.UserData holds the panel's
% children
p = clearPanel(num);
[k,m] = feval(analysis_module, 'install', num);
set(p, 'UserData', k);
if ~isempty(m)
    set(p,'UIContextMenu',m);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function registerModule(modules)
% installs modules in the module list
a1 = GetUIHandle(me,'analysis1');
curr = get(a1,'String');
if isempty(curr)
    curr = {};
elseif ~isa(curr,'cell')
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
function s = describe(filename,d)
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

function pos = getlimits(p_num)
% figures out the limits on the figure surrounded by the panel lines
% (because axes won't display on top of panels, we have to use width=1
% panels to create the drawing areas
p = findobj(get(gcbf,'children'),'tag',['analysis' p_num '_frame']);
p1 = get(p,'position');
pos = cat(1,p1{:});
pos = [min(pos(:,1)), min(pos(:,2)), max(pos(:,3)), max(pos(:,4))];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALYSIS MODULES (built-in)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% these functions are basically handles for the workhorse pre-post
% module, which maps a pre-computed statistic into time and histogram space
function [kids, menu] = pspdata(action, varargin)
[kids, menu] = prepost(action, 'pspdata', varargin{:});
% installs the marks for excluding data
if strcmp(action,'install')
%    installMarks(varargin{:})
end

function [kids, menu] = irdata(action, varargin)
[kids, menu] = prepost(action, 'irdata', varargin{:});

function [kids, menu] = srdata(action, varargin)
[kids, menu] = prepost(action, 'srdata', varargin{:});

function [kids, menu] = resting(action, varargin)
if strcmp(action,'install')
    [kids, menu] = prepost(action, 'resting', varargin{:});
else
    pre = calculateresting(varargin{2});
    post = calculateresting(varargin{3});
    [kids, menu] = prepost(action, 'resting', varargin{1}, pre, post);
end

function [kids, menu] = prepost(action, dataset, varargin)
% Displays pre-computed statistics on two axes, and computes p-values, etc
menu = [];
kids = [];
switch lower(action)
case 'install'
    p_num = varargin{1};
    pos = getlimits(p_num);
    p1 = pos(1) + 23;
    w = pos(3) * 0.6;
    kids(1) = axes('parent',gcbf,'tag',[p_num dataset '_axes1'],'units','pixels',...
          'position',[p1, pos(2) + 20, w, pos(4) * 0.75]);
    p1 = p1 + w + 23;
    w = pos(3) * 0.2;
    kids(2) = axes('parent',gcbf,'tag',[p_num dataset '_axes2'],'units','pixels',...
        'position',[p1, pos(2) + 20, w, pos(4) * 0.75]);
    p1 = p1 + w + 10;
    w = pos(3) * 0.11;
    kids(3) = uicontrol(gcbf,'tag',[p_num dataset '_text'], 'style','text',...
        'fontsize',4,'horizontalalignment','left',...
        'position',[p1, pos(2) + 10, w, pos(4) * 0.75]);
    menu = uicontextmenu('parent',gcbf);
    fcn = @pspdata_export;
    h = uimenu(menu,'Label','&Export',...
        'Callback',{fcn, p_num, dataset});
    
case 'analyze'
    panel = varargin{1};
    pre = varargin{2};
    post = varargin{3};
    bs = GetUIParam(me,'binsize','stringval');
    if ~isnumeric(bs)
        bs = 0.5;
    end
    [pre_data, pre_abstime, pre_err] = aligndata(pre, 'pre',dataset, bs);
    [post_data, post_abstime, post_err] = aligndata(post, 'post', dataset, bs);
    % time course
    a1 = findobj(gcbf,'tag',[panel dataset '_axes1']);
    set(a1,'nextplot','replacechildren')
    plot(pre_abstime,pre_data,'bo','parent',a1);
    set(a1,'nextplot','add')
    plot(post_abstime,post_data,'ro','parent',a1);
    % histograms
    a1 = findobj(gcbf,'tag',[panel dataset '_axes2']);
    set(a1,'nextplot','replacechildren')
    [b,x] = normhist(pre_data,10);
    if ~isempty(pre_data), plot(x,b,'b','parent',a1),end
    set(a1,'nextplot','add')
    [b,x] = normhist(post_data,10);
    if ~isempty(post_data), plot(x,b,'r','parent',a1),end
    % statistics
    norm_mode = GetUIParam(me,'norm_none','UserData');
    if ~strcmp(norm_mode,'norm_add')
        per = '%';
    else
        per = '';
    end
    if ~isempty(pre_data)
        [m s se] = stats(pre_data, norm_mode);
        sf = sprintf('Pre:\n Mn: %1.3g\n Std: %5.4g%s',...
            m,s,per);
    end
    if ~isempty(post_data)
        [m s se] = stats(post_data, norm_mode);
        sf = sprintf('%s\nPost:\n Mn: %1.3g\n Std: %5.4g%s',...
            sf,m,s,per);
    end
    if ~isempty(pre_data) & ~isempty(post_data)
        [d,p] = stats2(pre_data,post_data, norm_mode);
        sf = sprintf('%s\n\ndiff: %1.4g%s\nt-test: %3.6f',sf,d,per,p);
    end
    h = findobj(gcbf,'tag',[panel dataset '_text']);
    set(h,'string',sf,'tooltipstring',sf);
    
end

function [data, time, err, n, Y] = aligndata(datacell, mode, dataset, binsize)
% aligns and averages data sets. If mode=='pre', the last data
% point in each series is aligned, else, the first data point is aligned
data = [];
time = [];
err = [];
n = 1;
Y = {};
if isempty(datacell)
    return
end
d = cat(1,datacell{:});
if length(d) == 1
    data = getfield(d, dataset);
    time = getfield(d, 'abstime');
    if strcmp(mode,'pre')
        time = time - time(end);
    end
else
    rf = sprintf('{d.%s}', dataset);
    data = eval(rf);
    time = {d.abstime};
    if strcmp(mode,'pre')
        for i = 1:length(time)
            time{i} = time{i} - time{i}(end);
        end
        binsize = -binsize;
    end
    [data, time, err, n, Y] = CombineData(data, time, binsize);
end
if strcmp(mode,'post')
    time = time + 5;
end

function [m,stdev,stderr] = stats(dataset, norm_mode)
% computes statistics for single datasets
[m,stdev,stderr] = deal([]);
if ~isempty(dataset)
    m = mean(dataset);
    stdev = std(dataset);
    stderr = stdev/sqrt(length(dataset));
    if nargin == 1 | ~strcmp(norm_mode,'norm_add')
        stdev = abs(stdev/m) * 100;
        stderr = abs(stderr/m) * 100;
    end
end

function [diff, p] = stats2(data1, data2, norm_mode)
[diff, p] = deal([]);
m1 = mean(data1);
m2 = mean(data2);
if nargin > 2 & strcmp(norm_mode,'norm_add')
    diff = (m2-m1);
else
    diff = (m2-m1)/m1 * 100;
end
if ~isempty(data1) & ~isempty(data2)
    [h,p,ci,stats] = ttest2(data1,data2,0.05);
end

function [dc] = calculateresting(dc)
% calculates the mean resting level of each episode
for i = 1:length(dc)
    dc{i}.resting = mean(dc{i}.data,1);
end

function [b,x] = normhist(dataset,bins)
[b,x] = hist(dataset,bins);
b = b / length(dataset);

function pspdata_export(varargin)
    [fn, pn] = uiputfile('*.csv');
    if fn == 0
        return
    end
    norm = GetUIParam(me,'norm_none','UserData');
    [pre, post] = getData(norm);
    bs = GetUIParam(me,'binsize','stringval');
    if ~isnumeric(bs)
        bs = 0.5;
    end    
    pre = calculateresting(pre);
    post = calculateresting(post);
    dataset = varargin{4};
    
    [pre_dat, pre_at, s, n, pre_Y] = aligndata(pre,'pre',dataset,bs);
    [post_dat, post_at, s, n, post_Y] = aligndata(post,'post',dataset,bs);
    if isempty(pre_Y)
        d = [pre_at, post_at; pre_dat, post_dat]';
        sparsetblwrite(d, [], [],fullfile(pn,fn), ',');
    else
        sparsetblwrite([pre_Y;post_Y], [pre_at, post_at]', [],fullfile(pn,fn), ',');
    end
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [kids, menu] = psth(action, varargin)
% graphs the first presynaptic response against the first postsynaptic response
[kids,menu] = deal([]);
switch lower(action)
case 'install'
    p_num = varargin{1};
    pos = getlimits(p_num);
    p1 = pos(1) + 23;
    w = pos(3) * 0.6;
    kids(1) = axes('parent',gcbf,'tag',[p_num '_axes1'],'units','pixels',...
        'position',[p1, pos(2) + 20, w, pos(4) * 0.75]);
    fcn = @psth_export;
    kids(2) = uicontrol('style','pushbutton','tag',[p_num '_export'],'units','pixels',...
        'position',[pos(1) + pos(3) - 91, pos(2) + 20, 90, 21],'parent',gcbf,...
        'string','Export','Callback',{fcn,p_num});
case 'analyze' 
    panel = varargin{1};
    pre = varargin{2};
    post = varargin{3};
    a1 = findobj(gcbf,'tag',[panel '_axes1']);
    set(a1,'nextplot','replacechildren','xlimmode','auto','ylimmode','auto');
    if ~isempty(pre)
        m = mean(pre{1}.data,2);
        m = m - m(1);
        plot(pre{1}.time, m, 'b', 'parent', a1);
    end
    set(a1,'nextplot','add');
    if ~isempty(post)
        m = mean(post{1}.data,2);
        m = m - m(1);
        plot(post{1}.time, m, 'r', 'parent', a1);
    end
end

function psth_export(varargin)
p_num = varargin{3};
a1 = findobj(gcbf,'tag',[p_num, '_axes1']);
f = figure;
a = axes('parent',f,'nextplot','add');
c = get(a1,'children');
for i = 1:length(c)
    x = get(c(i),'Xdata');
    y = get(c(i),'ydata');
    l = get(c(i),'linestyle');
    plot(x,y,l,'parent',a,'color',get(c(i),'color'));
end