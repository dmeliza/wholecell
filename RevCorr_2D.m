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
% Q: how to ensure synchronization?  The LCD panel has a vsync line which
% can be run into a channel on the DAQ.  However, this is the internal refresh
% of the display, and not the time at which the frame changes.  cgflip returns
% a timestamp which is what we're using now, which seems to work pretty well.
% For some reason, either due to timing issues in the hardware or precision issues
% in the driver, frame rates (the rate at which the DAQ timer goes off) need to be
% multiples of ten.  Bad values cause visually noticible variance in the timing
% between frames.
%
% Alternatively, a loop could be used to play each frame, using pause() to
% separate them from one another temporally.  However, pause appears to be
% blocking, which isn't good for performance.
%
% Another concern is the maximum framerate, which is limited by the refresh rate
% of the display system.  85 Hz = ~12 ms.  NTSC is 60 Hz, but this is interlaced,
% so the true frame rate is more like ~33 ms.  Interlacing creates additional
% problems because there is a 16 ms transition between fully formed frames.
%
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

    p.t_res = cell2struct({'Frame rate', 'value', 50, 'ms'},f,2);
    p.y_res = cell2struct({'Y Pixels','value',4,cb},f_sb,2);
    p.x_res = cell2struct({'X Pixels','value',4,cb},f_sb,2);
    
    p.repeat = cell2struct({'Repeats (0=inf)','value',1},f_s,2);
    p.a_frames = cell2struct({'Stimulus Frames','value',1000,cb},f_sb,2);
    p.stim = cell2struct({'Stim File','fixed','',loadStim},f_sb,2);
    p.display = cell2struct({'Display', 'value', 2,cb},f_sb,2);
    p.input.description = 'Amplifier Channel';
    p.input.fieldtype = 'list';
    p.input.choices = GetChannelList(wc.ai);
    ic = get(wc.control.amplifier,'Index');
    p.input.value = ic;
    csd = cggetdata('csd');
    p.toolkit = cell2struct({'Toolkit:','fixed',csd.CogStdString},...
        f_s,2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
% The timer is used to tell the software when to flip to the next frame
global wc
analyze = @analyze;
flip = @nextFrame;
sr = get(wc.ai, 'SampleRate');
t_res = GetParam(me,'t_res','value');
a_int = sr/1000 * t_res * GetParam(me,'a_frames','value');
set(wc.ai,'SamplesPerTrigger', a_int);
set(wc.ai,'SamplesAcquiredActionCount', a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Trigger');
set(wc.ai,'TimerPeriod', t_res / 1000);
set(wc.ai,'TimerAction',{me,flip})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep.  Persistant data stored in two global variables
global wc timing frame gprimd;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('scope','status','String',get(wc.ai,'logfilename'));
% need a check to see if a movie is loaded...
% reset timing data and clear screen
a_frames = GetParam(me,'a_frames','value');
timing = zeros(a_frames+1,1);
frame = 1;
cgflip(0);
gprimd = cggetdata('gpd');
% bombs away
start([wc.ai]);
trigger([wc.ai]);
timing(1) = cgflip(0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clearDAQ()
% resets callbacks so we don't get recordings where we don't want'em
global wc
set(wc.ai,'SamplesAcquiredAction',{});
set(wc.ai,'TimerAction',{});
SetUIParam('wholecell','status','String',get(wc.ai,'Running'));        
set(wc.ai,'LoggingMode','Memory');
set(wc.ai,'LogFileName',NextDataFile);

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
% load sprites:
pix = x_res * y_res;
h = waitbar(0,['Loading movie (' num2str(a_frames) ' frames)']);
for i = 1:a_frames
    o = (i - 1) * pix + 1;
    cgloadarray(i,x_res,y_res,stim(o:o+pix-1),colmap,0);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nextFrame(obj, event)
% for speed, global variables contain critical parameters
global timing frame gprimd;

if frame < gprimd.NextRASKey
     cgdrawsprite(frame,0,0, gprimd.PixWidth, gprimd.PixHeight);
     frame = frame + 1;
     timing(frame) = cgflip;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function stim = getStimulus(filename)
% loads a mat file and returns the first (numeric) variable in the file
d = load(filename);
n = fieldnames(d);
if length(n) < 1
    error('No data in stimulus file');
end
stim = getfield(d,n{1});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% all data has been collected and we have timing data
% if the data is being written to disk the timing data must also be written
% ASAP
global timing
stop(obj);
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
