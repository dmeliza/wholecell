function varargout = RevCorr_LED(varargin)
%
% RevCorr_LED: A protocol for use with the wholecell toolkit.  Control up to
% two LED's with varying degrees of correlation.  Intended for monocular
% or binocular full-field stimulation of an animal while recording.  The user can
% select the frame rate of each LED and a file or mfile that describes the time sequence
% of each LED's activity.
% 
% Online analysis uses xcorr to look for the first moment of the temporal filter.
%
% void RevCorr_LED(action)
%
% Input:  a file containing one or two column vectors which represent the state of
%         each LED over the course of the acquisition.  Or an mfile that dynamically
%         generates these sequences.
%
% Output: The DAQ toolkit is responsible for sending the voltages to the LED's through
%         the analogoutput object, and recording the response of the cell through
%         the analoginput object.
%
% Details: The operation of this protocol is quite straightforward.  The user specifies
%          a frame rate and an output sequence.  The sequence is loaded into the daq's
%          analog output, and when the user clicks "Start" or "Record", the ai and ao
%          objects are triggered simultaneously.  Empirically, synchronization is very
%          tight between the input and output, so no additional signal is needed to
%          align the stimulus waveform with the response.
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
    p = defaultParams;
    fig = ParamFigure(me, p);
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
    p.sequence = struct('description','Sequence','fieldtype','file_in',...
                        'value','');
    p.s_max.description = 'Max LED Voltage';
    p.s_max.fieldtype = 'value';
    p.s_max.units = 'V';
    p.s_max.value = 3.6;
    p.s_min.description = 'Min LED Voltage';
    p.s_min.fieldtype = 'value';
    p.s_min.units = 'V';
    p.s_min.value = 2.0;
%     p.a_int = struct('description','Repeat Length','fieldtype','value',...
%                       'value',50,'units','s');
    p.repeat = struct('description','Repeats (0=inf)','fieldtype','value',...
                      'value',0.2);
    p.f_rate = struct('description','Frame Rate','fieldtype','value',...
                     'units','Hz','value',20);
%     p.d_rate = struct('description','Display Rate','fieldtype','value',...
%                       'value',10,'units','Hz');
    p.input.description = 'Amplifier Channel';
    p.input.fieldtype = 'list';
    p.input.choices = GetChannelList(wc.ai);
    ic = get(wc.control.amplifier,'Index');
    p.input.value = ic;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc
%display = @updateDisplay;
analyze = @analyze;
srate   = get(wc.ai, 'SampleRate');               % sample rate of ai
frate   = GetParam(me,'f_rate','value');           % frame rate of LED in Hz
%d_rate  = GetParam(me,'d_rate','value');          % update rate, Hz
len     = queueSequence(wc.ai, wc.ao);            % number of frames
a_int   = sr * GetParam(me,'a_int','value');      % analysis interval, samples
%update = fix(sr / u_rate); 
set(wc.ai,'SamplesPerTrigger',a_int);
%set(wc.ai,'TimerPeriod',1 / u_rate);
%set(wc.ai,'TimerAction',{me,display})
set(wc.ai,'SamplesAcquiredActionCount',a_int);
set(wc.ai,'SamplesAcquiredAction',{me,analyze});
set(wc.ai,'DataMissedAction',{me,'showerr'});
%set(wc.ai,'UserData',update);
set([wc.ai wc.ao],'TriggerType','Manual');
set(wc.ai,'ManualTriggerHwOn','Trigger');

set(wc.ao, 'SampleRate', frate);
% set(wc.ao,'SamplesOutputFcnCount', sr * a_int * 19);
% set(wc.ao,'SamplesOutputFcn',{me, requeue});

% Spool('stim','init');
% Spool('resp','init');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function startSweep()
% Begins a sweep
global wc;
stop([wc.ai wc.ao]);
flushdata(wc.ai);
fn = get(wc.ai,'LogFileName');
set(wc.ai,'LogFileName',NextDataFile(fn));    
SetUIParam('protocolcontrol','status','String',get(wc.ai,'logfilename'));
queueStimulus;
start([wc.ai wc.ao]);
trigger([wc.ai wc.ao]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function len = queueStimulus(ai, ao)
% queues data in the ao object, returning the length of the sequence (in frames)
% also writes the stimulus to disk if the ai is in disk-logging mode
p       = GetParam(me,'load_me','value');       % is a sequence cached?
if p
    seqf    = GetParam(me,'sequence','value');
    seq     = loadSequence(seqf);
else
    seq     = GetUIParam('protocolcontrol','status','UserData');
end

% rescale sequence to voltages
minV    = GetParam(me,'s_min','value');
maxV    = GetParam(me,'s_max','value');
seq     = (seq - min(min(seq)) * (maxV - minV) / max(max(seq)) + minV;

[len,n] = size(seq);                    % length and number of signals
nchan   = length(ao.Channel);           % number of channels
c       = zeros(len,nchan);             % need to fill all the channels
if n < nchan
    c(:,1:n) = seq;
elseif n > nchan
    c = seq(:,1:nchan);
else
    c = seq;
end
putdata(ao,c);                          % here is where the data gets sent to the ao obj

m = get(ai,'LoggingMode')
if ~strcmpi('memory',m)
    lf = get(ai,'Logfilename')
    writeStimulus(lf,seq);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seq = loadSequence(filename)
% loads the sequence from a file, throwing errors when appropriate
if ~exist(filename)
    errordlg(['Sequence file does not exist']);
    error('Unable to load sequence file');
end
[pn fn ext] = fileparts(filename)
switch lower(ext)
case '.mat'
    seq = load(filename);
    fn  = fieldnames(seq);      % load first field
    seq = getfield(seq,fn);
case '.m'
    seq = feval(filename);
otherwise
    errordlg(['Invalid sequence file!']);
    error('Unable to load sequence from file');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeStimulus(filename, stimulus)
% writes stimulus waveform to a mat file for later analysis
frate = GetParam(me,'f_rate','value');
[pn fn ext] = fileparts(filename);
save([pn filesep fn '.mat'],...
    'stimulus', 'frate');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% function updateDisplay(obj, event)
% % this method displays data, using peekdata to acquire the latest
% % bit of data
% samp = get(obj,'TimerPeriod');
% sr = get(obj,'SampleRate'); % samp/sec
% d = peekdata(obj,samp*sr);
% if length(d) == samp*sr % short stuff is discarded
%     sr = 1000/sr; % ms/samp
%     t = 0:sr:(length(d)-1)*sr;
%     plotData(t,d);
% end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function varargout = plotData(time, data)
% % updates the scope with the latest bit of data
% global wc
% 
% mode = GetParam('control.telegraph', 'mode');
% gain = GetParam('control.telegraph', 'gain');
% scope = getScope;
% if ~isempty(mode)
%     units = TelegraphReader('units',mean(data(:,mode)));
% else
%     units = 'V';
% end
% if ~isempty(gain)
%     gain = TelegraphReader('gain',mean(data(:,gain)));
% else
%     gain = 1;
% end
% lbl = get(scope,'YLabel');
% set(lbl,'String',['amplifier (' units ')']);
% % plot the data and average response
% index = wc.control.amplifier.Index;
% data = AutoGain(data(:,index), gain, units);
% Scope('scope',time, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analyze(obj, event)
% this function is called when the full set of data has been acquired
% it collects data from the buffer, plots it, and calls the analysis method
% if there are additional repeats to run, it calls startSweep()
global wc
stop([obj wc.ao]);
lfn       = get(obj,'LogFileName');
[pn fn e] = fileparts(lfn);
if ~strcmp('memory',lower(get(obj,'LoggingMode')))
    save(fullfile(pn,[fn '-param']),'param');
end
plotResults(obj, wc.ao);
r         = GetParam(me,'repeat','value');
if r == 0 | r > str2num(fn)
    startSweep;
else
    ClearAI(obj);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotResults(ai, ao)
% this method plots and analyzes the data in the buffer
in      = GetParam(me,'input','value');
[data, time, abstime] = getdata(obj);
axes(getScope)
plot(time,data(:,in));
% quick analysis using PCA_2D
stim    = GetUIParam('protocolcontrol','status','UserData');
srate   = get(ai,'SampleRate');     % sample rate
frate   = get(ao,'SampleRate');     % LED frame rate
y       = bindata(data(:,in),srate/frate,1);        % bin response to frame rate
options = struct('correct','no');
kern    = danlab_revcor(stim',y,10,frate,options);


% window = [-1000 200];
% 
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