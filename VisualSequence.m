function [] = VisualSequence(varargin)
%
% This protocol displays a 2D pixel sequence and records cellular responses.
% Uses Cogent Graphics toolkit for display.
%
% Input: The data for the pixel sequence is read from a file.  This can be 
%        an .s0 file, which has a structure defined in headers/s0_struct.m.  Or
%        it can be a .m file which returns an s0 structure. Or it can be an .s1
%        file, which is a .mat file containing an .s1 structure, which defines a
%        dynamically generated stimulus.
%
% Output: The DAQ toolkit stores the response from the cell.  This is made available
%         to the user, who can choose an analysis protocol, which is an mfile that takes
%         an r1 and an s0 structure for parameters.
% 
% Details: Synchronization data is recorded from a photocell which is placed in front
%          of a reserved area of the screen.  This area flashes between black to white
%          each time the frame changes.  The first frame change generates a positive-going
%          voltage, which triggers acquisition to start using a 'Software' trigger.
%          Frames are flipped at positive integer multiples of the hardware refresh rate.
%          In 1x playback mode each frame is displayed only once, while in slower playback
%          modes the same frame will be drawn more than once.
%          
%          The location and scaling of the sprites are loaded from the ancillary
%          CGDisplay module.
%
% Changes: 
% 1.1:     Adapted from RevCorr_2D.
% 1.5:     Added support for s1 files
% 1.10:    16 bit display now used, much faster
%
% $Id$

global wc

if isobject(varargin{1})
    feval(varargin{3},varargin{1:2});
    return;
end

if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action

case {'init','reinit'}
    CGDisplay('init')
    p = defaultParams;
    fig = findobj('tag',[lower(me) '.param']);        % checks if the param window is already
    if isempty(fig)                                   % open
        fig = ParamFigure(me, p);
    end
    getScope;
    
case 'start'
    setupHardware;
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    set(wc.ai,'LogFileName',fullfile(dir, '0000.daq'));    
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));    
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        feval(me,'stop');
    end
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));    
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    setupHardware;
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    
case 'stop'
    if (isvalid(wc.ai))
        ClearAI(wc.ai)
    end
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function p = defaultParams()
global wc;

    cb = @setLoadFlag;
    loadStim = @pickStimulus;

    f = {'description','fieldtype','value','units'};
    f_sb = {'description','fieldtype','value','callback'};
    f_s = {'description','fieldtype','value'};
    f_l = {'description','fieldtype','value','choices'};

    p.load_me = cell2struct({'if true reload stim before run','hidden',1},f_s,2);

    p.analysis = cell2struct({'Analysis','file_in','',},f_s,2);
    p.t_res = cell2struct({'Frame rate (1/x)', 'value', 2},f_s,2);
    p.repeat = cell2struct({'Repeats (0=inf)','value',1},f_s,2);
    p.stim = cell2struct({'Stim File','fixed','',loadStim},f_sb,2);
    p.display = cell2struct({'Display', 'value', 2,cb},f_sb,2);
    p.contrast = cell2struct({'Contrast [-1,1]', 'value', 2, cb},f_sb,2);
    ic = get(wc.control.amplifier,'Index');
    p.sync_c = cell2struct({'Sync Channel','list',ic,GetChannelList(wc.ai)},f_l,2);
    p.input = cell2struct({'Amplifier Channel','list',ic,GetChannelList(wc.ai)},...
        f_l,2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
analyze = @analyze;
len     = checkMovie(wc.ai) + 5;            % number of sprites in the movie
gprimd  = cggetdata('gpd');
v_res   = gprimd.RefRate100 / 100;      % frames/second
sr      = get(wc.ai, 'SampleRate');     % samples/second
t_res   = GetParam(me,'t_res','value'); % frames/sprite
a_int   = len / v_res * t_res * sr;     % samples
% acq params
set(wc.ai,'SamplesPerTrigger', a_int);
set(wc.ai,'SamplesAcquiredActionCount', a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'ManualTriggerHwOn','Start');
% hardware triggering (falling ttl on pfi0/Trig1):
set(wc.ai,'TriggerDelayUnits','seconds');
set(wc.ai,'TriggerDelay',0);     
set(wc.ai,'TriggerType','HwDigital');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Starts the acquisition engine.
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn     = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
start([wc.ai]);
cogstd('spriority','high');
frate  = GetParam(me,'t_res','value');
s  = GetUIParam('protocolcontrol','status','UserData');
CgPlayFrames(frate,s.seq);      % pass the sequence of sprites and the frame rate to CgPF()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setLoadFlag(varargin)
% sets the 'load_me' param to 1 so that the stimulus will be requeued
SetParam(me,'load_me',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function len = checkMovie(obj)
% checks to make sure there's a movie loaded
% returns the number of frames
p    = GetParam(me,'load_me','value');
if p
    queueStimulus;
end
stim = GetUIParam('protocolcontrol','status','UserData');
if strcmpi(stim.type,'s1')
    name = 'stim.s1';
    len  = size(stim.param,1);
else
    name = 'stim.s0';
    len  = size(stim.stimulus,3);
end
if ~strcmp(lower(get(obj,'LoggingMode')),'memory')
    [pn fn ext] = fileparts(get(obj,'logfilename'));
    WriteStructure([pn filesep name],stim);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function [] = queueStimulus()
% Loads a "movie" in the form of sprites.  Once the sprites are loaded into
% video memory they can be rapidly accessed.  The sequence in which the
% sprites should be played, as well as the original stimulus data, is stored
% in the status bar's UserData field.
movfile  = GetParam(me,'stim','value');
if ~isempty(movfile)
    % reset display toolkit
    disp     = GetParam(me,'display','value');
    cgshut;
    cgopen(1,16,0,disp);        % dc mode
    % run the mfile or load the .s0 file
    stim     = LoadMovie(movfile);
    stim.seq = CgQueueMovie(stim);                      % the sequence of sprites
    SetUIParam('protocolcontrol','status','UserData',stim);
    SetParam(me,'load_me',0);
end    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function pickStimulus(varargin)
% callback for the stimulus field, allows user to select
% a file that describes the stimulus
mod         = varargin{3};
param       = varargin{4};
s           = varargin{5};
t           = [mod '.' param];
h           = findobj(gcbf,'tag',t);
v           = get(h,'tooltipstring');           % this is the file to load
[pn fn ext] = fileparts(v);
od          = pwd;
if ~isempty(pn)
    cd(pn)
end
[fn2 pn2]   = uigetfile({'*.m;*.s0;*.s1','Stimulus Files (*.m,*.s0,*.s1)';...
                         '*.*','All Files (*.*)'});
cd(od)                 
if ~isnumeric(fn2)
    v       = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s       = SetParam(mod, param, v);
end
queueStimulus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clearDAQ()
% resets callbacks so we don't get recordings where we don't want'em
global wc
set(wc.ai,'SamplesAcquiredAction',{});
set(wc.ai,'TimerAction',{});
SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
set(wc.ai,'LoggingMode','Memory');
set(wc.ai,'LogFileName',NextDataFile);
set(wc.ai,'TriggerType','Manual')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% all data has been collected and we have timing data
% if the data is being written to disk the timing data must also be written
% ASAP
stop(obj);
param     = GetParam(me);

lfn       = get(obj,'LogFileName');
[pn fn e] = fileparts(lfn);
if ~strcmp('memory',lower(get(obj,'LoggingMode')))
    save(fullfile(pn,[fn '-param']),'param');
end
plotResults(obj);
r         = GetParam(me,'repeat','value');
if r == 0 | r > str2num(fn)
    startSweep;
else
    ClearAI(obj);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function [] = plotResults(obj)
% Plots the results and send them on for further analysis
in      = GetParam(me,'input','value');
sync    = GetParam(me,'sync_c','value');
[data, time, abstime] = getdata(obj);
axes(getScope)
plot(time,data(:,in));
% Get the analysis method
am      = GetParam(me,'analysis','value');
if ~isempty(am) & ~isnumeric(am) & exist(am,'file')
    % Generate the r1 structure
    % bin the data (rough, ignores variance in timing)
    [pn func ext] = fileparts(am);
    timing        = Sync2Timing(data(:,sync));
    units         = obj.Channel(in).Units;
    t_rate        = get(obj,'SampleRate');
    stim          = GetUIParam('protocolcontrol','status','UserData');
    feval(func,stim,struct('data',data(:,in),'timing',timing,'y_unit',units,'t_rate',t_rate));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function a = getScope()
% retrieves the handle for the scope axes
f       = findfig([me '.scope']);
set(f,'position',[288 314 738 508],'name','scope','numbertitle','off');
a       = get(f,'Children');
if isempty(a)
    a   = axes;
    set(a,'NextPlot','ReplaceChildren')
    set(a,'XTickMode','Auto','XGrid','On','YGrid','On','YLim',[-5 5])
    xlabel('Time (ms)')
    ylabel('amplifier (V)')
end