function [] = VisualEpisode(varargin)
%
% This protocol displays a 2D pixel sequence and records cellular responses.
% Uses Cogent Graphics toolkit for display.  It should be used instead of
% VisualSequence or Episode if there is a short sequence of frames that should
% be shown in sequence many times.  The user can specify the sequence of frames,
% the frame length and interframe interval, and also inject current through
% the analogoutput object.  For simplicity's sake, each frame is treated equally.
%
%
% Input: The data for the pixel sequence is read from a file.  This can be 
%        an .s0 file, which has a structure defined in headers/s0_struct.m.  Or
%        it can be a .m file which returns an s0 structure.
%
% Output: The DAQ toolkit stores the response from the cell.  This is made available
%         to the user, who can choose an analysis protocol, which is an mfile that takes
%         an r1 and an s0 structure for parameters.
% 
% Details: Synchronization data is recorded from a photocell which is placed in front
%          of a reserved area of the screen.  This area flashes between black to white
%          each time the frame changes.  Because data presentation on the screen needs
%          to be synchronized precisely with the analogoutput object, the only option
%          here is to use a hardware trigger (the software trigger used in FlashEpisode
%          is extremely imprecise.  The use of a hardware trigger means that preacquisition
%          doesn't work, so we have to play a frame with the sync square in it before 
%          any actual stimulus frame (delay hardcoded to 200 ms)
%          
%          The location and scaling of the sprites are loaded from the ancillary
%          CGDisplay module.
%
% Changes: 
% 1.1:     Adapted from VisualSequence and Episode
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

    f = {'description','fieldtype','value','units'};
    f_s = {'description','fieldtype','value'};
    f_l = {'description','fieldtype','value','choices'};
    f_cb = {'description','fieldtype','value','callback'};
    loadStim = @loadStimulus;
    
    % we need to insert parameters here once there are current injections involved
    p.frameinter    = cell2struct({'Frame interval', 'value', 32,'ms'},f,2);
    p.framelength   = cell2struct({'Frame Length','value',16,'ms'},f,2);
    p.stim          = cell2struct({'Stim File','fixed','',loadStim},f_cb,2);
    p.display       = cell2struct({'Display', 'value', 2},f_s,2);
    p.frequency     = cell2struct({'Ep. Freq','value',0.2,'Hz'},f,2);
    ic              = get(wc.control.amplifier,'Index');
    p.sync_c        = cell2struct({'Sync Channel','fixed','hardware'},f_s,2);
    p.input         = cell2struct({'Amplifier Channel','list',ic,GetChannelList(wc.ai)},...
                                  f_l,2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition.  Some things are held constant:
% 200 ms acquired before first frame
% 200 ms after last frame + interframeinterval
% same frame length and interval for all frames
global wc
analyze = @analyze;
len     = checkMovie(wc.ai);            % number of sprites in the movie
gprimd  = cggetdata('gpd');
v_res   = gprimd.RefRate100 / 100;      % frames/second
fl      = GetParam(me,'framelength','value');
fint    = GetParam(me,'frameinter','value');
dt      = 1000/v_res;                   % ms
fl      = fl - mod(fl,dt) + dt;         % find next longest appropriate frame length
fint    = fint - mod(fint,dt) + dt;
a_int   = 400 + len * (fl + fint);      % length of episode, ms
sr      = get(wc.ai, 'SampleRate');     % samples/second
a_int   = a_int * sr/1000;              % length of episode, samples
% acq params
set(wc.ai,'SamplesPerTrigger', a_int);
set(wc.ai,'SamplesAcquiredActionCount', a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
% hardware triggering for ao and ai:
set(wc.ai,'TriggerDelayUnits','seconds');
set(wc.ai,'TriggerDelay',0);            % hardware triggers have to have a >= zero delay
set(wc.ai,'TriggerType','HwDigital');
set(wc.ao,'TriggerType','HwDigital');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Starts the acquisition engine.
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn     = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
queueStimulus;
start([wc.ai wc.ao]);
pause(0.2);
playFrames

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = playFrames()
% plays the sequence of frames, preceded by an initial sync rectangle
% thus the sync rectangle is on whenever a frame is not; if the signal is
% recorded this will allow reconstruction of stimulus onset and offset
gprimd  = cggetdata('gpd');
v_res   = gprimd.RefRate100 / 100;      % frames/second
dt      = 1000/v_res;                   % ms
dur     = GetParam(me,'framelength','value');
del     = GetParam(me,'frameinter','value');
ndur    = fix(fl/dt);               % number of frames to hold image
ndel    = fix(fint/dt);             % number of frames to leave image off
nini    = fix(200/dt);              % number of frames to wait after start of episode
[x y pw ph] = CGDisplay_Position;

movfile  = GetParam(me,'stim','value');
stim     = LoadMovie(movfile);

len      = size(stim.stimulus,3);       % # of frames
seq      = CgQueueMovie(stim);

cgrect(-320,-240,100,100,[1,1,1])       % sync rectangle, hard-coded
% timing is now critical
cgflip(0,0,0)
for i=1:nini
    cgflip('V');
end
for i=1:len
    cgdrawsprite(i,x,y, pw, ph);
    cgrect(-320,-240,100,100,[0,0,0]);
    cgflip(0,0,0);
    for i = 1:ndur
        cgflip('V');
    end
    cgrect(-320,-240,100,100,[1,1,1]);
    cgflip(0,0,0);
    for i = 1:ndel
        cgflip('V');
    end
end
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function len = checkMovie(obj)
% checks to make sure there's a movie loaded
% returns the number of frames
len      = 0;
movfile  = GetParam(me,'stim','value');
stim     = LoadMovie(movfile);
if ~isempty(stim)
    len  = size(stim.stimulus,3);
    if ~strcmp(lower(get(obj,'LoggingMode')),'memory')
        [pn fn ext] = fileparts(get(obj,'logfilename'));
        WriteStructure([pn filesep name],stim);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function loadStimulus(varargin)
mod         = varargin{3};
param       = varargin{4};
s           = varargin{5};
t           = [mod '.' param];
h           = findobj(gcbf,'tag',t);
v           = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2]   = uigetfile([pn filesep '*.s0']);
if ~isnumeric(fn2)
    v       = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s       = SetParam(mod, param, v);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% function pickStimulus(varargin)
% % callback for the stimulus field, allows user to select
% % a file that describes the stimulus
% mod         = varargin{3};
% param       = varargin{4};
% s           = varargin{5};
% t           = [mod '.' param];
% h           = findobj(gcbf,'tag',t);
% v           = get(h,'tooltipstring');           % this is the file to load
% [pn fn ext] = fileparts(v);
% od          = pwd;
% if ~isempty(pn)
%     cd(pn)
% end
% [fn2 pn2]   = uigetfile({'*.m;*.s0','Stimulus Files (*.m,*.s0)';...
%                          '*.*','All Files (*.*)'});
% cd(od)                 
% if ~isnumeric(fn2)
%     v       = fullfile(pn2,fn2);
%     set(h,'string',fn2,'tooltipstring',v)
%     s       = SetParam(mod, param, v);
% end
% queueStimulus;

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
% clear the stimulus display
cgflip(0,0,0)
% plots and analyzes the data
stop(obj)
[data, time, abstime] = getdata(obj);
plotData(data, time, abstime);
t                     = 1 / GetParam(me,'frequency','value');
t2                    = GetParam(me,'ep_length','value') / 1000;
pause(t - t2)
a                     = get(obj,'SamplesAcquiredAction');
if ~isempty(a)
    startSweep;
else
    ClearAI(obj);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotData(data, time, abstime)
% plots the data

index       = GetParam(me,'input','value');
data        = data(:,index);
axes(getScope)
% plot the data and average response
a               = get(gca, 'UserData'); % avgdata is now a cell array
if isempty(a)
    numtraces   = 1;
    avgdata     = data;
else
    avgdata     = a{2};
    numtraces   = a{1} + 1;
    avgdata     = avgdata + (data - avgdata) / (numtraces);
end
plot(time * 1000, [data avgdata])
a               = {numtraces, avgdata};
set(gca,'UserData', a);

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