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
% a timestamp which may be of use.  In addition, because the DAQ timer is used
% to switch sprites and flip the frames, we may be good enough using the DAQ
% engine's timestamps for these timer events.
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
    ClearAO(wc.ao);
    if (isvalid(wc.ai))
        stop(wc.ai);
        set(wc.ai,'SamplesAcquiredAction',{});
        set(wc.ai,'TimerAction',{});
        SetUIParam('wholecell','status','String',get(wc.ai,'Running'));        
        set(wc.ai,'LoggingMode','Memory');
        set(wc.ai,'LogFileName',NextDataFile);
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

    p.t_res = cell2struct({'Frame rate', 'value', 50, 'ms'},f,2);
    p.y_res = cell2struct({'Y Pixels','value',4},f_s,2);
    p.x_res = cell2struct({'X Pixels','value',4},f_s,2);
    
    p.a_frames = cell2struct({'Stimulus Frames','value',1000},f_s,2);
    p.stim = cell2struct({'Stim File','file_in',''},f_s,2);
    p.display = cell2struct({'Display', 'value', 2},f_s,2);
    p.input.description = 'Amplifier Channel';
    p.input.fieldtype = 'list';
    p.input.choices = GetChannelList(wc.ai);
    ic = get(wc.control.amplifier,'Index');
    p.input.value = ic;
    csd = cggetdata('csd');
    p.toolkit = cell2struct({'Toolkit:','fixed',csd.CogStdString},...
        {'description','fieldtype','value'},2);
    
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
set(wc.ai,'DataMissedAction',{me,'showerr'});
set(wc.ai,'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Trigger');
set(wc.ai,'TimerPeriod', t_res / 1000);
set(wc.ai,'TimerAction',{me,flip})

% this would be better served by a custom field in the param
% window that sets up the display window whenever the user changes
% the value.  This would allow the sprites to remain in video memory
% and speed up loading prior to protocol initiation.
disp = GetParam(me,'display','value');
cgopen(1,8,0,disp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep.  Persistant data stored in two global variables
global wc timing frame gprimd;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('scope','status','String',get(wc.ai,'logfilename'));
queueStimulus;  % move this elsewhere to save time
% reset timing data and clear screen
a_frames = GetParam(me,'a_frames','value');
timing = zeros(a_frames,2);
frame = 1;
cgflip(0);
gprimd = cggetdata('gpd');
% bombs away
start([wc.ai]);
trigger([wc.ai]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function queueStimulus()
% Loads a "movie" in the form of sprites.  Once the sprites are loaded into
% video memory they can be rapidly accessed.
% load parameters:
x_res = GetParam(me,'x_res','value');
y_res = GetParam(me,'y_res','value');
a_frames = GetParam(me,'a_frames','value');
mseqfile = GetParam(me,'stim','value');
stim = getStimulus(mseqfile);
% setup colormap:
colmap = gray(2);
cgcoltab(0,colmap);
cgnewpal;
% load sprites:
pix = x_res * y_res;
h = waitbar(0,['Loading movie (0/' num2str(a_frames) ' frames)']);
for i = 1:a_frames
    o = (i - 1) * pix + 1;
    cgloadarray(i,x_res,y_res,stim(o:o+pix-1),colmap,0);
    waitbar(i/a_frames,h,['Loading movie (' num2str(i) '/' num2str(a_frames) ' frames)']);
end
close(h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nextFrame(obj, event)
% for speed, global variables contain critical parameters
global timing frame gprimd;
if frame < gprimd.NextRASKey
    cgdrawsprite(frame,0,0, gprimd.PixWidth, gprimd.PixHeight);
    timing(frame,:) = [now,cgflip];
    frame = frame + 1;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeStimulus(filename, stimulus, stimrate, analysis_interval)
% writes stimulus waveform to a mat file for later analysis
[pn fn ext] = fileparts(filename);
save([pn filesep fn '.mat'],...
    'stimulus', 'stimrate', 'analysis_interval');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% all data has been collected and we have timing data
% if the data is being written to disk the timing data must also be written
% ASAP
global timing
stop(obj);
param = GetParam(me);
if strcmp('memory',lower(get(obj,'LoggingMode')))
    lfn = get(obj,'LogFileName');
    [pn fn ext] = fileparts(lfn);
    save(fullfile(pn,fn),'timing','param');
end
% get data
[data, time, abstime] = getdata(obj);
% align the data
stim_start = datevec(timing(1) - datenum(abstime));
stim_start = stim_start(6); % this breaks if there's more than one minute of delay
i = max(find(time < stim_start)) + 1;
resp = data(i:end,param.input.value);
time = time(i:end) - time(i);
stim_times = timing(:,2) - timing(1,2);
% bin the data (rough, ignores variance in timing)
t_resp = 1000 / get(obj,'SampleRate');
t_stim = param.t_res.value;
r = bindata(resp,fix(t_stim/t_resp));
r = r - mean(r);
% reconstruct the stimulus (as an N by X matrix)
s_frames = length(r);
stim = getStimulus(param.stim.value);
pix = param.x_res.value * param.y_res.value * s_frames; % # of pixels
s = reshape(stim(1:pix),param.x_res.value*param.y_res.value, s_frames);
s = permute(s,[2 1]);
% reverse correlation:
options.correct = 'no';
hl_est = danlab_revcor(s,r,5,fix(1000/t_stim),options);
% combine first 5 lags into a spatial plot
k = mean(hl_est,1);
k = reshape(k,6,6)';
mx = max(max(abs(k)));
figure,imagesc(k,[-mx mx]);
colormap(gray);
set(gca,'XTick',[],'YTick',[])

%figure,plot(time,resp);
% xlabel('Time (s)');
% ylabel('Response (V)');

% window = [-1000 200];
% [data, time, abstime] = getdata(obj);
% index = wc.control.amplifier.Index;
% stim = Spool('stim','retrieve');
% samplerate = get(obj,'SampleRate');
% t_res = GetParam(me,'t_res','value');
% stimstart = get(wc.ao,'InitialTriggerTime');
% c = revcorr(data(:,index)', stim, samplerate,...
%     1000 / t_res, stimstart, abstime, window);
% s = [me '.analysis'];
% f = findobj('tag', s);
% if isempty(f) | ~ishandle(f)
%     f = figure('tag', s, 'numbertitle', 'off', 'name', s);
% end
% t = window(1):t_res:window(2);
% figure(f);
% d = get(f,'UserData');
% d = cat(1,d,c);
% a = mean(d,1);
% p = plot(t, [c; a]);
% xlabel('Time (ms)');
% set(f,'name',[s ' - ' num2str(size(d,1)) ' scans']);
% set(f,'UserData',d);
% Spool('stim','delete');
% 
% startSweep;

%%%%%%%%%%%%%%%%%%%%%%%%5
function showerr(obj, event)
keyboard;