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
% a timestamp which may be of use.
%
% Another concern is the maximum framerate, which is limited by the refresh rate
% of the display system.  85 Hz = ~12 ms.  NTSC is 60 Hz, but this is interlaced,
% so the true frame rate is more like ~33 ms.  Interlacing creates additional
% problems because there is a 16 ms transition between fully formed frames.
%
% The raw voltage trace isn't displayed because the program will be constantly
% looping in order to play the movie, and any callbacks will probably mean dropped
% frames.
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
    
    p.a_int = cell2struct({'Sequence Length','value',30,'s'},f,2);
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
global wc
analyze = @analyze;
sr = get(wc.ai, 'SampleRate');
a_int = sr * GetParam(me,'a_int','value');
set(wc.ai,'SamplesPerTrigger', a_int);
set(wc.ai,'SamplesAcquiredActionCount', a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'DataMissedAction',{me,'showerr'});
set(wc.ai,'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Trigger');

% t_res = GetParam(me,'t_res','value');
% sr = 1000 / t_res ;

disp = GetParam(me,'display','value');
cgopen(1,8,0,disp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('scope','status','String',get(wc.ai,'logfilename'));
% start([wc.ai]);
% trigger([wc.ai]);
runStimulus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function runStimulus()
% Presents stimulus to the animal through the graphics toolkit.
% The stimulus file is always the same, so what we need to store is
% some kind of timing data so that we can figure out what was displayed when.
% Currently we play data as fast as possible (ignoring t_res param). At least
% two strategies to reduce frame rate: (1) insert pause into loop,
% (2) use the DAQ's timer to cause flips.
global wc
t_res = GetParam(me,'t_res','value'); % ignored for the moment
x_res = GetParam(me,'x_res','value');
y_res = GetParam(me,'y_res','value');
a_int = GetParam(me,'a_int','value');
mseqfile = GetParam(me,'stim','value');
d = load(mseqfile);
if (isfield(d,'msequence'))
    mseq = d.msequence(1:1000,:);
else
    error('Stimulus file does not contain msequence data');
end

update = a_int * 1000 / t_res; % ignored for the moment
colmap = gray(2); % 1 bit stimulus
cgcoltab(0,colmap);
cgnewpal;
gpd = cggetdata('gpd');
x_lim = gpd.PixWidth;
y_lim = gpd.PixHeight;
S = zeros(length(mseq)+1,1);
S(1) = now;
for i = 1:length(mseq)
    % load data into video memory.  Alternatively, we could try to load all
    % the sprites: it looks like we have room for 10000 sprites, which at
    % our frame rate is something like 500 s of stimulus.
    cgloadarray(1,x_res,y_res,mseq(i,:),colmap,0);
    cgdrawsprite(1,0,0,x_lim,y_lim);
    S(i+1) = cgflip;
end
keyboard;

function wn = mseq(mseqfile, samples)
% loads mseq data from a file
s_max = GetParam(me,'s_max','value');
s_min = GetParam(me,'s_min','value');
d = load(mseqfile);
if isfield(d,'msequence')
    [m n] = size(d.msequence); 
    wn = d.msequence(1:samples,1);
    % adjust data to proper LED stimulus
    wn(find(wn>0)) = s_max;
    wn(find(wn<=0)) = s_min;
else
   errordlg('Invalid input file');
   error([mseqfile ' is not a valid input file']);
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeStimulus(filename, stimulus, stimrate, analysis_interval)
% writes stimulus waveform to a mat file for later analysis
[pn fn ext] = fileparts(filename);
save([pn filesep fn '.mat'],...
    'stimulus', 'stimrate', 'analysis_interval');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% this method analyzes the data, using getdata to clear the latest
% data from the buffer
global wc
window = [-1000 200];
[data, time, abstime] = getdata(obj);
index = wc.control.amplifier.Index;
stim = Spool('stim','retrieve');
samplerate = get(obj,'SampleRate');
t_res = GetParam(me,'t_res','value');
stimstart = get(wc.ao,'InitialTriggerTime');
c = revcorr(data(:,index)', stim, samplerate,...
    1000 / t_res, stimstart, abstime, window);
s = [me '.analysis'];
f = findobj('tag', s);
if isempty(f) | ~ishandle(f)
    f = figure('tag', s, 'numbertitle', 'off', 'name', s);
end
t = window(1):t_res:window(2);
figure(f);
d = get(f,'UserData');
d = cat(1,d,c);
a = mean(d,1);
p = plot(t, [c; a]);
xlabel('Time (ms)');
set(f,'name',[s ' - ' num2str(size(d,1)) ' scans']);
set(f,'UserData',d);
Spool('stim','delete');

startSweep;



%%%%%%%%%%%%%%%%%%%%%%%%5
function showerr(obj, event)
keyboard;