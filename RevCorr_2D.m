function varargout = RevCorr_2D(varargin)
%
% This protocol displays a 2D pixel sequence and records cellular responses
% for reverse correlation.  Uses Cogent Graphics toolkit for display. (A useful
% thing would be to generalize calls to the toolkit so that different toolkits
% can be used, for instance on different platforms)
%
% Input: The data for the pixel sequence is read from a file.
% Output: The DAQ toolkit stores the response from the ceFll
%
%
% 1.8:
% synchronization method changed. A region of the display is dedicated to a photosensor
% which will detect frame changes.  The first frame change generates a positive-going
% voltage, which triggers acquisition to start.  The 'TriggerType' is 'Software', although
% because no pre-trigger data needs to be acquired we could use a hardware-specific
% trigger type.  The same line used for triggering is also used to detect frame drops
% during off-line analysis because each change in frame will result in a change of state
% for this region of the display.  Only positive integer fractions will be accepted
% for the frame rate of the stimulus because the method of playback is to flip,
% as fast as possible, between frames.  In 1x playback each frame is substituted with the
% next one, and in slower playback modes the same frame will be drawn to the screen
% multiple times.
%
% Interlaced displays should be avoided because the transition between frames will take
% twice the stated frame rate and intermediate frames will be a montage of the two
% proper frames.
%
% 1.12:
% Generalized the function of this protocol.  Instead of generating the msequence
% movie, it now accepts both .mat and .m files for the stim parameter.  In the case of
% a .mat file it will attempt to load the stimulus using LoadStimulus, which looks for
% the x_res, y_res, colmap, and stimulus fields.  In the case of a .m file, it will
% attempt to feval() the function, which it expects to return a structure with the
% correct fields.
%
% TODO:
% This protocol is still pretty hard-wired.  It needs the CogGph toolkit, and it
% attempts to open the stimulus window at 640x480 without doing any error checking.
% Also it would be nice to divide the movie-making function (e.g. turning the msequence
% into an NxN movie) from the protocol, which could then be generalized to play
% sparse noise or natural scenes.
%
% Use cgscale to make drawing calls resolution-independent.

% The raw voltage trace isn't displayed so that we avoid dropping frames as much as
% possible.  Buy an oscillscope.
% 
% void RevCorr_2D(action)
%
% action is {'init'} 'play', 'record', or 'stop'
% other actions are used as internal callbacks
%
% parameters:
% (output)
%     - t_res: frame rate of LED
%     - x_res: number of X pixels
%     - y_res: number of Y pixels
%     - stim: the file from which to read the stimulus
%     - display: the monitor on which to display the stimulus
% (input)
%     - input: the amplifier channel of the DAQ board
%     - sync: the channel on the DAQ board for sync data
% (analysis)
%     - s_len: length of stimulus to consider for rev corr
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
    cgloadlib; % error checking needed here for missing toolkit
    cgopen(1,8,0,2);
    p = defaultParams;
    fig = ParamFigure(me, p);
    Scope('init');
    
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
        if get(wc.ai,'samplesavailable') > 0
            analyze(wc.ai,[]);
        end
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

    p.p1 = cell2struct({'Param 1','value',2,cb},f_sb,2);
    p.a_frames = cell2struct({'Stimulus Frames','value',1000,cb},f_sb,2);
    p.y_res = cell2struct({'Y Pixels','value',4,cb},f_sb,2);
    p.x_res = cell2struct({'X Pixels','value',4,cb},f_sb,2);
    p.load_me = cell2struct({'if true reload stim before run','hidden',1},f_s,2);

    p.t_res = cell2struct({'Frame rate (1/x)', 'value', 2},f_s,2);
    p.repeat = cell2struct({'Repeats (0=inf)','value',1},f_s,2);
    p.stim = cell2struct({'Stim File','fixed','',loadStim},f_sb,2);
    p.display = cell2struct({'Display', 'value', 2,cb},f_sb,2);
    p.sync_val = cell2struct({'Sync Voltage','value',2,'V'},f,2);
    ic = get(wc.control.amplifier,'Index');
    p.sync_c = cell2struct({'Sync Channel','list',ic,GetChannelList(wc.ai)},f_l,2);
    p.input = cell2struct({'Amplifier Channel','list',ic,GetChannelList(wc.ai)},...
        f_l,2);
    gprimd = cggetdata('gpd');
    p.v_res = cell2struct({'Refresh:','fixed',gprimd.RefRate100 / 100},...
        f_s,2);
    csd = cggetdata('csd');
    p.toolkit = cell2struct({'Toolkit:','fixed',csd.CogStdString},...
        f_s,2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
analyze = @analyze;
len = checkMovie(wc.ai); % number of sprites in the movie
gprimd = cggetdata('gpd');
v_res = gprimd.RefRate100 / 100; % frames/second
sr = get(wc.ai, 'SampleRate'); %samples/second
t_res = GetParam(me,'t_res','value'); % frames/sprite
a_int = len / v_res * t_res * sr; %samples
% acq params
set(wc.ai,'SamplesPerTrigger', a_int);
set(wc.ai,'SamplesAcquiredActionCount', a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'ManualTriggerHwOn','Start');
% hardware triggering:
sync = GetParam(me,'sync_c','value');
sync_v = GetParam(me,'sync_val','value');
curr = getsample(wc.ai);
curr = curr(sync); % current value of sync detector
set(wc.ai,'TriggerDelayUnits','seconds');
set(wc.ai,'TriggerDelay',0);
set(wc.ai,'TriggerType','Software');
set(wc.ai,'TriggerCondition','Rising');
set(wc.ai,'TriggerConditionValue',curr+sync_v);
set(wc.ai,'TriggerChannel',wc.ai.Channel(sync));
set(wc.ai,'TriggerAction',{});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Starts the acquisition engine.
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
start([wc.ai]);
cogstd('spriority','high');
playStimulus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function playStimulus()
% plays the movie at the appropriate frame rate.
global timing;
% check that stimulus is the proper length
frate = GetParam(me,'t_res','value');
gprimd = cggetdata('gpd'); %max frame is given by gprimd.NextRASKey - 1
if gprimd.NextRASKey < 2
    queueStimulus;
end
CgPlayFrames(frate);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setLoadFlag(varargin)
% sets the 'load_me' param to 1 so that the stimulus will be requeued
SetParam(me,'load_me',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function len = checkMovie(obj)
% checks to make sure there's a movie loaded
% returns the number of frames
p = GetParam(me,'load_me','value');
if p
    queueStimulus;
end
stim = GetUIParam('protocolcontrol','status','UserData');
if ~strcmp(lower(get(obj,'LoggingMode')),'memory')
    [pn fn ext] = fileparts(get(obj,'logfilename'));
    WriteStructure([pn filesep 'stim.s0'],stim);
end
len = size(stim.stimulus,3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function stim = queueStimulus()
% Loads a "movie" in the form of sprites.  Once the sprites are loaded into
% video memory they can be rapidly accessed.

% reset display toolkit
disp = GetParam(me,'display','value');
cgshut;
cgopen(1,8,0,disp);
% these parameters are only used if the movfile is an mfile
a_frames = GetParam(me,'a_frames','value');
x_res = GetParam(me,'x_res','value');
y_res = GetParam(me,'y_res','value');
p1 = GetParam(me,'p1','value');

movfile = GetParam(me,'stim','value');
stim = LoadMovie(movfile, x_res, y_res, a_frames, p1);
SetUIParam('protocolcontrol','status','UserData',stim);
CgQueueMovie(stim);
SetParam(me,'load_me',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function pickStimulus(varargin)
% callback for the stimulus field, allows user to select
% a .mat or .m file that describes the stimulus
mod = varargin{3};
param = varargin{4};
s = varargin{5};
t = [mod '.' param];
h = findobj(gcbf,'tag',t);
v = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2] = uigetfile([pn filesep '*.m']);
if ~isnumeric(fn2)
    v = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s = SetParam(mod, param, v);
end
stim = queueStimulus;
SetParam(me,'x_res',stim.x_res);
SetParam(me,'y_res',stim.y_res);
SetParam(me,'a_frames',size(stim.stimulus,3));
ParamFigure(me);

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
global timing
stop(obj);
% blank out display
cgflip(0);
cgflip(0);
param = GetParam(me);

lfn = get(obj,'LogFileName');
[pn fn ext] = fileparts(lfn);
if ~strcmp('memory',lower(get(obj,'LoggingMode')))
    save(fullfile(pn,[fn '-timing']),'timing','param');
end
plotResults(obj,timing);
r = GetParam(me,'repeat','value');
if r == 0 | r > str2num(fn)
    startSweep;
else
    ClearAI(obj);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function plotResults(obj, timing)
% Plots the results of the reverse correlation
% get data
in = GetParam(me,'input','value');
sync = GetParam(me,'sync_c','value');
[data, time, abstime] = getdata(obj);
Scope('plot','plot', time, data(:,in));
% bin the data (rough, ignores variance in timing)
t_resp = 1000 / get(obj,'SampleRate'); %ms/sample
t_res = GetParam(me,'t_res','value'); % frames/sprite
gpd = cggetdata('gpd');
t_stim = t_res * 1000 / gpd.RefRate100 * 100; %ms/sample
r = bindata(data(:,in),fix(t_stim/t_resp));
r = r - mean(r);
stim_times = timing(:,1) - timing(1);
% recover and condition the stimulus
r_frames = length(r);
stim_struct = GetUIParam('protocolcontrol','status','UserData');
s = stim_struct.stimulus;
x_res = stim_struct.x_res;
y_res = stim_struct.y_res;
s_frames = size(s,3);
if s_frames > r_frames
    frames = r_frames;
    s = s(:,:,1:frames);
else
    frames = s_frames;
    r = r(1:frames);
end
s = reshape(s,x_res*y_res,frames)';
% reverse correlation:
options.correct = 'no';
options.display = 'no';
Fs = fix(1000/t_stim);
hl_est = danlab_revcor(s,r,5,Fs,options);
Plot2DKernel(hl_est,r,s,stim_times,[x_res,y_res],Fs);
