function [] = VisualEpisode(varargin)
%
% This protocol displays a 2D pixel sequence and records cellular responses.
% Uses Cogent Graphics toolkit for display.  It should be used instead of
% VisualSequence or Episode if there is a short sequence of frames that should
% be shown in sequence many times.  The user can specify the sequence of frames,
% the frame length and interframe interval, and also inject current through
% the analogoutput object.  
%
% The order and length of time each frame is shown is determined by a sequence vector,
% which consists of indices into a 3-dimensional stimulus array.  Each element of
% the vector specifies the frame of the stimulus to show; if an element is repeated
% the frame is kept on screen.  Indices of 0 imply a blank screen.
%
%
% Input: The data for the pixel sequence is read from a file.  This can be 
%        an .s2 file, which has a structure defined in headers/s2_struct.m.  Or
%        it can be a .m file which returns an s2 structure.
%
% Output: The DAQ toolkit stores the response from the cell.  The protocol plots the
%         most recently acquired sweep and the average of all previously acquired sweeps.
% 
% Details: Synchronization data is recorded from a photocell which is placed in front
%          of a reserved area of the screen.  This area flashes between black to white
%          each time the frame changes.  Because data presentation on the screen needs
%          to be synchronized precisely with the analogoutput object, the only option
%          here is to use a hardware trigger (the software trigger used in FlashEpisode
%          is extremely imprecise.  The use of a hardware trigger means that preacquisition
%          doesn't work, so we have to specify blank frames before any actual stimulus
%          frames.  The first frame has a white sync rectangle, which should generate
%          a *downward* TTL pulse.  Successive frames alternate the sign of the sync
%          pixel whenever the frame changes (not every real refresh of the screen)
%
%          Acquisition length is independent of the length of the stimulus; if there are
%          only a few frames, these will be played and the DAQ toolkit left to finish out
%          the acquisition.  All times are relative to the beginning of the episode.
%          
%          The location and scaling for the sprites are loaded from the ancillary
%          CGDisplay module.
%
% Changes: 
% 1.1:     Adapted from VisualSequence and Episode
% 1.3:     Designed to supercede FlashEpisode
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
    ClearAO(wc.ao)
    ClearAI(wc.ai)
    
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
    loadStim = @pickStimulus;
    
    % we need to insert parameters here once there are current injections involved
    p.inj_length  = cell2struct({'Inj Length','value',6,'ms'},f,2);
    p.inj_delay   = cell2struct({'Inj Delay','value',200,'ms'},f,2);
    p.inj_gain    = cell2struct({'Inj Gain','value',1},f_s,2);
    p.inj_channel = cell2struct({'Command','list',1,GetChannelList(wc.ao)},f_l,2);
    
    p.stim_len      = cell2struct({'Stim Length','value', 300, 'ms'},f,2);
    p.stim_delay    = cell2struct({'Stim Delay','value',200,'ms'},f,2);
    p.stim_gain     = cell2struct({'Stim Gain','value',10,'(V)'},f,2);
    p.stim_channel  = cell2struct({'Stimulator','list',1,GetChannelList(wc.ao)},f_l,2);
    
    p.stim          = cell2struct({'Stim File','fixed','',loadStim},f_cb,2);
    p.display       = cell2struct({'Display', 'value', 2},f_s,2);
    p.frequency     = cell2struct({'Ep. Freq','value',0.2,'Hz'},f,2);
    p.ep_length     = cell2struct({'Ep. Length','value',2000,'ms'},f,2);
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
% reset display
% setupVisual;
% acq params
sr       = get(wc.ai, 'SampleRate');
length   = GetParam(me,'ep_length','value');
len      = length * sr / 1000;
set(wc.ai,'SamplesPerTrigger',len)
set(wc.ai,'SamplesAcquiredActionCount',len)
set(wc.ai,'SamplesAcquiredAction',{me, analyze}) 
set(wc.ai,'ManualTriggerHwOn','Start')
set(wc.ao,'SampleRate', 1000)
% hardware triggering via TTL to PFI0 and PFI6
set(wc.ai,'TriggerDelay',0)
set([wc.ai wc.ao], 'TriggerType','HwDigital')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [seq, bg] = setupVisual()
% visual output: loads a .s0 file into video memory
% returns the sequence of frames to play
seq = [];
stimfile = GetParam(me,'stim','value');
[s st]   = LoadStimulusFile(stimfile);
if isempty(s)
    error(st)
else
    for i = 1:size(s.stimulus,3)
        stim  = s.stimulus(:,:,i);
        dim   = size(stim);
        dim2  = dim .* ceil(100./dim);            % nice integer scaleup
        stim = reshape(stim',1,prod(dim));
        cgloadarray(i,s.x_res,s.y_res,stim,s.colmap,dim2(1),dim2(2))
    end
    seq = s.sequence; 
    bg  = s.colmap(1,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function queueStimulus()
% populates the wc.ao data channels.  It's necessary to upsample to
% at least 1 kHz in order to avoid strange buffer overruns in the DAQ driver
global wc

len         = GetParam(me,'ep_length','value');                 %ms
dt          = 1000 / get(wc.ao,'SampleRate');                   %ms/sample
p           = zeros(len / dt, length(wc.ao.Channel));
% stimulator
ch          = GetParam(me,'stim_channel','value');
del         = GetParam(me,'stim_delay','value') / dt; %samples
i           = del+1:(del+ GetParam(me,'stim_len','value'));
p(i,ch)     = GetParam(me,'stim_gain','value');
% injection
ch          = GetParam(me,'inj_channel','value'); 
del         = GetParam(me,'inj_delay','value') / dt; %samples
dur         = GetParam(me,'inj_length','value') / dt;               %samples
gain        = GetParam(me,'inj_gain','value');
i           = del+1:del+dur;
p(i,ch)     = gain;
putdata(wc.ao,p);

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function pickStimulus(varargin)
mod         = varargin{3};
param       = varargin{4};
s           = varargin{5};
t           = [mod '.' param];
h           = findobj(gcbf,'tag',t);
v           = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2]   = uigetfile([pn filesep '*.s2']);
if ~isnumeric(fn2)
    v       = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s       = SetParam(mod, param, v);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = playFrames()
% plays the sequence of frames, preceded by an initial sync rectangle
% thus the sync rectangle is on whenever a frame is not; if the signal is
% recorded this will allow reconstruction of stimulus onset and offset
% frames are loaded by setupVisual() each time Play is pressed
% while queueStimulus has to be called for each sweep
gprimd  = cggetdata('gpd');

[x y pw ph] = CGDisplay_Position;

[seq, bg] = setupVisual;
len       = length(seq);       % # of frames

syncmap  = [1 1 1; 0 0 0];
sync     = 1;
for i = 1:len
    fr   = seq(i);
    % draw frame if index is nonzero
    if fr > 0
        cgdrawsprite(fr,x,y,pw,ph)
    else
        cgrect(0,0,640,480,bg)
    end
    % switch sign of sync rectangle
    if i == 1 | fr ~= seq(i-1)
        sync    = ~sync;
    end
    cgrect(-320,-240,100,100,syncmap(sync+1,:))       % sync rectangle, hard-coded
    cgflip(0,0,0)
end


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