function [] = Flasher(varargin)
%
% This is a specialized protocol for recording the impulse responses of a cell
% or field to a set of images.  It should be used instead of VisualEpisode if
% each image will be shown in the same manner (e.g. flashed for 33 ms), and if
% interactions between the responses to frames need to be minimized (because
% frames are shown in a random order, allowing 2nd-order interactions between
% frames to be averaged out)
%
%
% Input: The data for the pixel sequence is read from a file.  This can be
%        a matfile with a structure, or an mfile that returns a structure.  The
%        appropriate structure must contain a stimulus and a colmap field (s0 and s2
%        files work fine)
%
%        The user is also allowed to specify a current injection time/length/gain, and
%        which frames should be accompanied by the injection.  For simplicity's sake
%        only one output channel is used.
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
%          
%          The location and scaling for the sprites are loaded from the ancillary
%          CGDisplay module.
%
% Changes: 
% 1.1:     Adapted from VisualEpisode
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
    % write the s2 or s0 file to disk in the data directory
    stimfile = GetParam(me,'stim','value');
    [s st]   = LoadStimulusFile(stimfile);
    if isempty(s)
        error(st)
    end
    WriteStructure(fullfile(dir,newdir,'stimulus.s2'),s)
    % open a file to store parameter sequence
    fid = fopen(fullfile(dir,newdir,'sequence.txt'),'at');
    setUIParam('protocolcontrol','status','UserData',fid);
    
    setupHardware;
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    
case 'stop'
    ClearAO(wc.ao)
    ClearAI(wc.ai)
    closeLog;
    
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
    p.inj_frames  = cell2struct({'Inj Images (0=all)','string','[0]'},f_s,2);
    p.play_frames  = cell2struct({'Play Images (0=all)','string','[0]'},f_s,2);
    p.inj_channel = cell2struct({'Command','list',1,GetChannelList(wc.ao)},f_l,2);
    
    p.stim          = cell2struct({'Stim File','fixed','',loadStim},f_cb,2);
    p.display       = cell2struct({'Display', 'value', 2},f_s,2);
    p.contrast      = cell2struct({'Contrast [-1,1]', 'value', 1},f_s,2);
    p.iti           = cell2struct({'InterEp. Interv','value',3000,'ms'},f,2);
    p.ep_length     = cell2struct({'Ep. Length','value',2000,'ms'},f,2);
    p.fr_length     = cell2struct({'Frames/Image','value',2,'ref'},f,2);
    ic              = get(wc.control.amplifier,'Index');
    p.sync_c        = cell2struct({'Sync Channel','fixed','hardware'},f_s,2);
    p.input         = cell2struct({'Amplifier Channel','list',ic,GetChannelList(wc.ai)},...
                                  f_l,2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition.
global wc
analyze = @analyze;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Starts the acquisition engine.
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn     = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));  
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
% Load visual data
[seq, fnum] = setupVisual;
% Store fnum in wc.ai's UserData so it can be extracted from the file later. Brilliant, huh?
set(wc.ai, 'UserData', fnum);
% except it doesn't work, so we have to append shit to a log
mod     = get(wc.ai,'LoggingMode');
if ~strcmpi(mod,'Memory')
    fid = GetUIParam('protocolcontrol','status','UserData');
    % checks for a valid handle (doesn't open anything)
    fn  = fopen(fid);   
    if ~isempty(fn)
        fprintf(fid,'%d\n', fnum - 1);
    end
end
queueStimulus(fnum);
start([wc.ai wc.ao]);
playFrames(seq);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [seq, fnum] = setupVisual()
% visual output: loads a .s0 or .s2 file into memory, picks a random frame
% and returns the framenumber (for storage) and the background color
stimfile = GetParam(me,'stim','value');
[s st]   = LoadStimulusFile(stimfile);
if isempty(s)
    error(st)
else
    % scale the colormap
    con     = GetParam(me,'contrast','value');    % equals the range of the colormap
    cmap    = s.colmap .* con;
    s.colmap = cmap - mean(mean(cmap)) + 0.5;       % reset mean to gray
    z       = size(s.stimulus,3);
    % pick a random frame
    picks   = str2num(GetParam(me,'play_frames','value'));
    fnum    = unidrnd(z-1,1,1) + 1;             % random frame > 1 (1 is the background)
    % now we have to deal with the case where the user only wants certain images played
    picks   = intersect(picks,1:z-1) + 1;           % if this is empty, keep the image
    while ~isempty(picks)
        if ismember(fnum,picks)
            picks = [];                         % valid frame, exit loop
        else
            fnum = unidrnd(z-1,1,1) + 1;
        end
    end
    % rescale and load the frame
    loadFrame(s,1,1);
    loadFrame(s,fnum,2);
    % generate the sequence
    len     = ceil(abs(GetParam(me,'fr_length','value')));
    seq     = ones(len+20);
    seq(13:13+len-1) = 2;                         % offset of 12 frames (200 ms at 60Hz)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = unidrnd(n, i, j)
% override the stats uniform discrete rand distribution as it sucks
% or rather, we want to make sure that every frame is played roughly the same #
% of times.  This is going to be managed using a stored list.  Which needs
% to be reset every time the number of possible states changes
rn = [];
if ispref('wholecell')
    d = getpref('wholecell');
    if isfield(d,'flasher-rands')
        rn = getfield(d,'flasher-rands');
    end
end
if isempty(rn)
    ints = repmat(1:n,1,4);        % take the integers from 1 to n, replicate 4 times
    ind  = randperm(length(ints));  % randomly permute the indices
    rn    = ints(ind);               % pull out the permuted index
end
r   = rn(1);        % return the first number in the array
if length(rn) > 1
    rn = rn(2:end);
else
    rn = [];
end
setpref('wholecell','flasher-rands',rn);


%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = loadFrame(s, fnum, snum)
stim  = s.stimulus(:,:,fnum);
dim   = size(stim);
dim2  = dim .* ceil(100./dim);            
stim = reshape(stim',1,prod(dim));
cgloadarray(snum,s.x_res,s.y_res,stim,s.colmap,dim2(1),dim2(2))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function queueStimulus(fnum)
% populates the wc.ao data channels.  It's necessary to upsample to
% at least 1 kHz in order to avoid strange buffer overruns in the DAQ driver
% checks the frame number against the user's preferences for injection, if this
% is not zero or not equal to one of the selected frames, no injection is made
global wc
len         = GetParam(me,'ep_length','value');                 %ms
dt          = 1000 / get(wc.ao,'SampleRate');                   %ms/sample
p           = zeros(len / dt, length(wc.ao.Channel));

frames      = str2num(GetParam(me,'inj_frames','value'));
ind         = find(frames==(fnum-1));
if frames==0 | ~isempty(ind)
    % injection
    ch          = GetParam(me,'inj_channel','value'); 
    del         = GetParam(me,'inj_delay','value') / dt; %samples
    dur         = GetParam(me,'inj_length','value') / dt;               %samples
    gain        = GetParam(me,'inj_gain','value');
    i           = del+1:del+dur;
    p(i,ch)     = gain;
end
putdata(wc.ao,p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = playFrames(seq)
% plays the sequence of frames, preceded by an initial sync rectangle
% thus the sync rectangle is on whenever a frame is not; if the signal is
% recorded this will allow reconstruction of stimulus onset and offset
% frames are loaded by setupVisual() each time Play is pressed
% while queueStimulus has to be called for each sweep
gprimd  = cggetdata('gpd');

[x y pw ph] = CGDisplay_Position;

syncmap  = [1 1 1; 0 0 0];
sync     = 1;
for i = 1:length(seq)
    fr   = seq(i);
    cgdrawsprite(fr,x,y,pw,ph)
    % switch sign of sync rectangle
    if i == 1 | fr ~= seq(i-1)
        sync    = ~sync;
    end
    cgrect(-320,-240,100,100,syncmap(sync+1,:))       % sync rectangle, hard-coded
    cgflip(0,0,0)
end
% redraw the last frame at the end but with black sync rectangle
cgdrawsprite(fr,x,y,pw,ph)
cgrect(-320,-240,100,100,syncmap(2,:));
cgflip(0,0,0)

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
f       = getScope('init');                       % initialize the graph axes
setpref('wholecell','flasher-rands',[]);          % reset random number sequence

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
% cgflip(0,0,0)
% plots and analyzes the data
stop(obj)
[data, time, abstime] = getdata(obj);
fnum                  = get(obj,'UserData');
plotData(data, time, abstime, fnum);
t                     = GetParam(me,'iti','value');
pause(t/1000);
a                     = get(obj,'SamplesAcquiredAction');
if ~isempty(a)
    startSweep;
else
    ClearAI(obj);
    closeLog;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotData(data, time, abstime, fnum)
% plots the data;
% Have to load the stimulus file (for the umpteenth time) to get grouping data
index       = GetParam(me,'input','value');
data        = data(:,index);
axes(getScope('get',fnum-1))
% plot the data and average response
a               = get(gca, 'UserData'); % avgdata is now a cell array
if isempty(a)
    numtraces   = 1;
    avgdata     = data;
else
    avgdata     = a{2};
    numtraces   = a{1} + 1;
    if length(avgdata) == length(data)
        avgdata     = avgdata + (data - avgdata) / (numtraces);
    else
        avgdata     = data;
        numtraces   = 1;
    end
end
plot(time * 1000, [data avgdata])
a               = {numtraces, avgdata};
set(gca,'UserData', a);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function a = getScope(action, arg)
% the scope is a series of plots, one for each frame number (or group)
% This function is used for two things: If action is 'init', the current
% stimulus is loaded, and a new window with the correct number of plots is
% opened.  If the action is 'get' and arg is the number of the frame,
% getScope will figure out which axes should be used for the plot and
% return the handle.
switch lower(action)
case 'init'
    f       = findfig([me '.scope']);
    set(f,'position',[288 314 738 508],'name','scope','numbertitle','off','doublebuffer','on');
    clf
    sf      = GetParam(me,'stim','value');
    [s,st]  = LoadStimulusFile(sf);
    if isempty(s)
        num = 4
    elseif isfield(s,'group')
        num = size(s.group,1);
    else
        num = size(s.stimulus,3) - 1;
    end
    for i = 1:num
        a = subplot(num,1,i);
        set(a,'NextPlot','ReplaceChildren')
        set(a,'XTickMode','Auto','XGrid','On','YGrid','On')%,'YLim',[-5 5])
        ylabel(num2str(i))
    end
    xlabel('Time (ms)')
    a       = f;
    s.num   = num;
    set(a,'UserData',s);       % store the stim struct for future use
otherwise
    f       = findobj('tag',[me '.scope']);
    if isempty(f)
        f   = getScope('init');
    else
        figure(f)
    end
    st      = get(f,'UserData');
    if isfield(st,'group')
        [i,j]   = find(st.group==arg);
        if ~isempty(i)
            arg = i + 1;
        end
    end
    a       = subplot(st.num,1,arg-1);
end

%%%%%%%%%%55
function [] = closeLog()
fid = GetUIParam('protocolcontrol','status','UserData');
if isnumeric(fid)
    fn  = fopen(fid);
    if ~isempty(fn)
        fclose(fid);
    end
end
SetUIParam('wholecell','status','UserData',[]);
