function varargout = RevCorr_2D(varargin)
%
% This protocol displays a 2D pixel sequence and records cellular responses
% for reverse correlation.  Uses Cogent Graphics toolkit for display. (A useful
% thing would be to generalize calls to the toolkit so that different toolkits
% can be used, for instance on different platforms)
%
% Input: The data for the pixel sequence is read from a file.
% Output: The DAQ toolkit stores the response from the cell
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
% TODO:
% This protocol is still pretty hard-wired.  It needs the CogGph toolkit, and it
% attempts to open the stimulus window at 1280x1024 without doing any error checking.
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
    p = defaultParams;
    fig = OpenParamFigure(me, p);
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
    setupHardware;
    llf = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(llf);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));    
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    startSweep;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    
case 'stop'
    if (isvalid(wc.ai))
        stop(wc.ai);
        clearDAQ;
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

    cb = @queueStimulus;
    loadStim = @loadStimulus;

    f = {'description','fieldtype','value','units'};
    f_sb = {'description','fieldtype','value','callback'};
    f_s = {'description','fieldtype','value'};
    f_l = {'description','fieldtype','value','choices'};

    p.t_res = cell2struct({'Frame rate (1/x)', 'value', 2},f_s,2);
    p.y_res = cell2struct({'Y Pixels','value',4,cb},f_sb,2);
    p.x_res = cell2struct({'X Pixels','value',4,cb},f_sb,2);
    
    p.repeat = cell2struct({'Repeats (0=inf)','value',1},f_s,2);
    p.a_frames = cell2struct({'Stimulus Frames','value',1000,cb},f_sb,2);
    p.stim = cell2struct({'Stim File','fixed','',loadStim},f_sb,2);
    p.display = cell2struct({'Display', 'value', 2,cb},f_sb,2);
    p.sync_val = cell2struct({'Sync Voltage','value',2,'V'},f,2);
    ic = get(wc.control.amplifier,'Index');
    p.sync_c = cell2struct({'Sync Channel','list',ic,GetChannelList(wc.ai)},f_l,2);
    p.input = cell2struct({'Amplifier Channel','list',ic,GetChannelList(wc.ai)},...
        f_l,2);
    csd = cggetdata('csd');
    p.toolkit = cell2struct({'Toolkit:','fixed',csd.CogStdString},...
        f_s,2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
analyze = @analyze;
sr = get(wc.ai, 'SampleRate');
t_res = GetParam(me,'t_res','value');
a_int = sr/1000 * t_res * GetParam(me,'a_frames','value');
% acq params
set(wc.ai,'SamplesPerTrigger', a_int);
set(wc.ai,'SamplesAcquiredActionCount', a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Trigger');
% hardware triggering:
sync = GetParam(me,'sync_c','value');
sync_v = GetParam(me,'sync_val','value');
curr = getsample(wc.ai);
curr = curr(sync); % current value of sync detector
set(wc.ai,'TriggerDelayUnits','seconds');
set(wc.ai,'TriggerDelay',0);
set(wc.ai,'TriggerType','HwAnalogChannel');
set(wc.ai,'TriggerCondition','InsideRegion');
set(wc.ai,'TriggerConditionValue',[curr+sync_v, curr+sync_v+10]);
set(wc.ai,'TriggerChannel',wc.ai.Channel(sync));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Starts the acquisition engine.
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('scope','status','String',get(wc.ai,'logfilename'));
start([wc.ai]);
playStimulus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function playStimulus()
% plays the movie at the appropriate frame rate.
% need a check to see if a movie of the appropriate length is loaded...

% reset timing data and clear screen
a_pix = GetParam(me,'a_frames','value');
frate = GetParam(me,'t_res','value');
a_frames = a_pix * frate;
timing = zeros(a_frames+1,1);
frame = 1;
sync = 1;
cgflip(0);
gprimd = cggetdata('gpd'); %max frame is given by gprimd.NextRASKey
% bombs away
for i = 1:a_frames;
    cgdrawsprite(frame+1,0,0, gprimd.PixWidth, gprimd.PixHeight);
    cgmakesprite(1,1,1,sync);
    cgdrawsprite(1,-gprimd.PixWidth/2,-gprimd.PixHeight/2,100,100);
    if mod(i,frate) == 0
        frame = frame + 1;
        sync = ~sync;
        % some kind of progress indicator?
    end
    timing(i) = cgflip;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function queueStimulus(varargin)
% Loads a "movie" in the form of sprites.  Once the sprites are loaded into
% video memory they can be rapidly accessed.
% load parameters:
disp = GetParam(me,'display','value');
x_res = GetParam(me,'x_res','value');
y_res = GetParam(me,'y_res','value');
a_frames = GetParam(me,'a_frames','value');
mseqfile = GetParam(me,'stim','value');
stim = getStimulus(mseqfile);
% reset display toolkit
cgshut;
cgopen(1,8,0,disp);

% setup colormap:
colmap = gray(2);
cgcoltab(0,colmap);
cgnewpal;
% load sync sprite
cgloadarray(1,1,1,1,colmap,0);
% load sprites:
pix = x_res * y_res;
h = waitbar(0,['Loading movie (' num2str(a_frames) ' frames)']);
for i = 1:a_frames
    o = (i - 1) * pix + 1;
    cgloadarray(i+1,x_res,y_res,stim(o:o+pix-1),colmap,0);
    waitbar(i/a_frames,h);
end
close(h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function loadStimulus(varargin)
mod = varargin{3};
param = varargin{4};
s = varargin{5};
t = [mod '.' param];
h = findobj(gcbf,'tag',t);
v = get(h,'tooltipstring');
[pn fn ext] = fileparts(v);
[fn2 pn2] = uigetfile([pn filesep '*.mat']);
if ~isnumeric(fn2)
    v = fullfile(pn2,fn2);
    set(h,'string',fn2,'tooltipstring',v)
    s = SetParam(mod, param, v);
end
queueStimulus;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function stim = getStimulus(filename)
% loads a mat file and returns the first (numeric) variable in the file
d = load(filename);
n = fieldnames(d);
if length(n) < 1
    error('No data in stimulus file');
end
stim = getfield(d,n{1});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clearDAQ()
% resets callbacks so we don't get recordings where we don't want'em
global wc
set(wc.ai,'SamplesAcquiredAction',{});
set(wc.ai,'TimerAction',{});
SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
set(wc.ai,'LoggingMode','Memory');
set(wc.ai,'LogFileName',NextDataFile);


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
    save(fullfile(pn,fn),'timing','param');
end
plotResults(obj,timing);
r = GetParam(me,'repeat','value');
if r == 0 | r > str2num(fn)
    startSweep;
else
    clearDAQ;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function plotResults(obj, timing)
% Plots the results of the reverse correlation
% get data
[data, time, abstime] = getdata(obj);
% align the data to the stim times
stim_start = timing(2) - timing(1);
i = max(find(time < stim_start)) + 1;
resp = data(i:end,GetParam(me,'input','value'));
time = time(i:end) - time(i);
% bin the data (rough, ignores variance in timing)
t_resp = 1000 / get(obj,'SampleRate');
t_stim = GetParam(me,'t_res','value');
r = bindata(resp,fix(t_stim/t_resp));
r = r - mean(r);
stim_times = timing(2:length(r)+1) - timing(2);
% reconstruct the stimulus (as an N by X matrix)
s_frames = length(r);
stim = getStimulus(GetParam(me,'stim','value'));
x_res = GetParam(me,'x_res','value');
y_res = GetParam(me,'y_res','value');
pix = x_res * y_res * s_frames; % # of pixels
s = reshape(stim(1:pix),x_res * y_res, s_frames);
s = permute(s,[2 1]);
% reverse correlation:
options.correct = 'no';
options.display = 'no';
Fs = fix(1000/t_stim);
hl_est = danlab_revcor(s,r,5,Fs,options);
Plot2DKernel(hl_est,r,s,stim_times,[x_res,y_res],Fs);
