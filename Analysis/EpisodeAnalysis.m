function [] = EpisodeAnalysis()

% A specialized analysis application for use with episodic data, which often
% represents precisely timed repeats of a cellular response to stimulus presentation
% (for instance, extracellular stimuluation or visual flashes).  Episodes tend to
% be short in length, and the data that needs to be extracted is commonly the behavior
% of some variable over the course of the experiment.
%
% Previous incarnations of EpisodeAnalysis only supported three predefined parameters,
% the PSP (or PSC) amplitude (or slope), and the input and series resistance.  Because
% episodic acquisition is now being used for more complex stimuli, including multiple
% frames, this is a severe limitation, so the user is now allowed to select any number
% of parameters for analysis.
%
% This is implemented by creating a "window" of analysis that is typically 100-200 ms long
% over which some analysis function operates.  For instance, if the user is interested
% in the response to a single shock to the cortex, a single window can be specified for the
% PSP immediately following the stimulus artifact, and a "slope" function specified,
% which returns the slope of the response between two time offsets.
%
% A second major change is designed to speed up the display of data.  Normally the user
% will be presented by an average trace, while analysis functions will operate on single
% sweeps.  The final results will be binned at whatever rate the user specifies.  Binning
% will only function over the final output of the analysis filters, reducing the amount of
% computation time used for displaying binned traces.
%
% Usage:  EpisodeAnalysis()  [all arguments are internal callbacks]
%
% $Id$

error(nargchk(0,0,nargin))

initFigure;
initValues;

%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Figure specification:

function [] = initFigure()
% initialize the main figure window
cb = getCallbacks;
BG = [1 1 1];
f = OpenFigure(me,'position',[360   343   750   450],...
    'color',BG,'menubar','none');
% Frame 1: Trace selection
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[10 175 200 270]);
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[25 415 160 20],...
    'Fontsize',10,'fontweight','bold','String','Traces');
h = InitUIControl(me, 'traces', 'style','list',...
    'Callback',cb.picktraces,'Max',2,...
    'position', [20 275 180 140],'backgroundcolor',BG);
h = InitUIControl(me, 'average', 'style', 'checkbox', 'backgroundcolor', BG,...
    'Callback',cb.selectaverage,'position',[20 255 180 20], 'String', 'Average Traces',...
    'Value', 1);
h = InitUIControl(me, 'channels', 'style', 'list',...
    'Callback',cb.pickchannels,'position', [20 185 180 70],'backgroundcolor',BG);
% Frame 2: Parameter selection
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[10 10 200 160]);
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[25 140 160 20],...
    'Fontsize',10,'fontweight','bold','String','Parameters');
h = InitUIControl(me, 'parameters', 'style','list',...
    'Callback',cb.pickparams,...
    'position', [20 40 180 100],'backgroundcolor',BG);
%h = InitUIControl(me, 'addparam', '
% Axes:
h = InitUIObject(me, 'response', 'axes', 'units','pixels','position',[255 70 480 360],...
    'nextplot','replacechildren','Box','On');
xlabel('Time(ms)')
ylabel('Response')
% Status bar
h = InitUIControl(me, 'status', 'style', 'text', 'backgroundcolor', BG,...
    'position', [255 0 480 20],'String','(status)');
% Menus
file = uimenu(gcf, 'Label', '&File');
m    = uimenu(file, 'Label', '&Open Response...','Callback',cb.menu, 'tag', 'm_resp');
m    = uimenu(file, 'Label', 'Open &Parameters...','Callback',cb.menu,'tag','m_param');
m    = uimenu(file, 'Label', '&Save Parameters...', 'Callback', cb.menu,'tag','m_save');
m    = uimenu(file, 'Label', '&Export Results...', 'Callback', cb.menu,'tag','m_export');
m    = uimenu(file, 'Label', 'E&xit', 'Callback', cb.menu, 'Separator', 'On','tag','m_exit');

% par  = uimenu(gcf, 'Label', '&Parameters');
% m    = uimenu(par, 'Label', '

op   = uimenu(gcf,'Label','&Operations');
m    = uimenu(op, 'Label', 'Remove &Baseline', 'Callback', cb.menu, 'tag', 'm_baseline');
m    = uimenu(op, 'Label', '&Align Episodes', 'Callback', cb.menu, 'tag', 'm_align');
m    = uimenu(op, 'Label', 'Re&scale', 'Callback', cb.menu, 'tag', 'm_rescale');

function [] = initValues()
% Initializes some app data so that calls to getappdata don't break
setappdata(gcf,'dir',pwd)       % current directory
setappdata(gcf,'r0',[])         % response file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:
function [] = picktraces(obj, event)
plotTraces

function [] = selectaverage(obj, event)
plotTraces

function [] = pickchannels(obj,event)
plotTraces

function [] = pickparams(obj, event)

function [] = menu(obj, event)
% handles menu callbacks
tag = get(obj, 'tag');
switch lower(tag)
case 'm_resp'
    % load responses (r0 files)
    path    = getappdata(gcf, 'dir');
    [fn pn] = uigetfile([path filesep '*.r0'],'Load Traces (r0)');
    if ~isnumeric(fn)
        [r0 str] = LoadResponseFile(fullfile(pn,fn));
        if ~isempty(r0)
            setappdata(gcf, 'r0', r0);
            updateDisplay;
        end
        setappdata(gcf,'dir',pn);
        SetUIparam(me,'status','String',str);
    end
otherwise
    disp(tag)
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals:

function [] = updateDisplay()
% updates fields in the GUI with new data's properties
r0 = getappdata(gcf, 'r0');
if ~isempty(r0)
    [samp sweep chan] = size(r0.data);
    % update trace list
    tr = (1:sweep)';
    c  = cellstr(num2str(tr));
    SetUIParam(me,'traces','String',c);
    SetUIParam(me,'traces','Value',tr);
    % update channel list
    if isfield(r0,'channels')
        c = {r0.channels.ChannelName};
    else
        c  = cellstr(num2str((1:chan)'));
    end
    SetUIParam(me,'channels','String',c);
    % plot traces
    plotTraces;
end    

function [] = plotTraces()
% replots traces
avg = GetUIParam(me,'average','Value');
tr  = GetUIParam(me,'traces','Value');
chn = GetUIParam(me,'channels','Value');
r0  = getappdata(gcf,'r0');
if ~isempty(r0)
    a   = GetUIHandle(me,'response');
    axes(a);
    cla
    if avg == 0
        hold on
        p = plot(r0.time, r0.data(:,tr,chn));
        set(p,'Color',[0.5 0.5 0.5],'linewidth',0.1);
    end
    data = mean(r0.data(:,tr,chn),2);
    plot(r0.time, data, 'k');

end

function out = me()
out = mfilename;

function out = getCallbacks()
% returns a structure with function handles to functions in this mfile
% no introspection in matlab so we have to do this by hand
fns = {'picktraces','pickchannels','selectaverage','pickparams','menu'};
out = [];
for i = 1:length(fns)
    sf = sprintf('out.%s = @%s;',fns{i},fns{i});
    eval(sf);
end