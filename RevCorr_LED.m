function varargout = RevCorr_LED(varargin)
%
% This protocol uses a flashing LED to determine the temporal
% receptive field of a cell in current or voltage clamp.  The voltage to
% the LED is output (gaussian white noise) and the signal from the amplifier
% is recorded.  The LED signal is stored for reverse correlation analysis.
%
% Online analysis looks for the first moment of the temporal filter (TBI).
%
% void RevCorr_LED(action)
%
% action is {'init'} 'play', 'record', or 'stop'
% other actions are used as internal callbacks
%
% parameters:
% (output)
%     - s_max: maximum output voltage to LED
%     - s_res: number of distinct output voltages
%     - t_res: frame rate of LED
% (analysis)
%     - s_len: length of stimulus to consider for rev corr
%     - r_thresh: minimum response to be considered a response
%
% $Id$

global wc

if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action

case {'init','reinit'}
    p = defaultParams;
    fig = OpenParamFigure(me, p);
    Scope('init');
    
case 'start'
    setupHardware;
    setupScope(getScope, wc.control.amplifier, control);
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    %SetUIParam('scope','status','String',['Sweeps Acquired: 0']);
    wc.episode.lastlogfilename = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(wc.episode.lastlogfilename);
    set(wc.ai,'LogFileName',fullfile(dir, '0000.daq'));
    EpisodeStats('clear');
    startSweep;
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        Episode('stop');
    end
    control = getValues;
    setupHardware(control);
    setupScope(getScope, wc.control.amplifier, control);
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    %SetUIParam('scope','status','String',['Sweeps Acquired: 0']);
    % data is stored in a directory, one file per sweep.
    wc.episode.lastlogfilename = get(wc.ai,'LogFileName');
    [dir newdir] = fileparts(wc.episode.lastlogfilename);
    s = mkdir(dir, newdir);
    set(wc.ai,'LogFileName',fullfile(dir,newdir, '0000.daq'));
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    EpisodeStats('clear');
    startSweep;
    
    
case 'stop'
    if (isvalid(wc.ao))
        set(wc.ao,'StopAction','');
        stop(wc.ao);
    end
    if (isvalid(wc.ai))
        stop(wc.ai);
        set(wc.ai,'LoggingMode','Memory');
        SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
        wc.episode.lastlogfilename = [];
        set(wc.ai,'LogFileName',NextDataFile);
    end

case 'sweep'
    data = varargin{2};
    time = varargin{3};
    abstime = varargin{4};
    if isvalid(wc.ai)
        fn = get(wc.ai,'LogFileName');
        set(wc.ai,'LogFileName',NextDataFile(fn));
    end
    plotData(data, time, abstime, getScope, wc.control.amplifier.Index);
    
case 'newsweep'
    if ~isempty(wc.episode.lastlogfilename)
        startSweep;
    end

case 'value_changed_callback' % called whenever a field is edited
    wc.control.episode = getValues;
    
case 'load_command_callback'
    [fn pn] = uigetfile('*.mat','Load command pulse');
    c = load([pn fn]);
    if (isfield(c,'command'))
        SetUIParam(me,'command_gain','UserData',c.command);
        Episode('value_changed_callback');
    end
    
case 'view_command_callback'
    a = axes;
    d = GetUIParam(me,'command_gain','UserData');
    if ~isempty(d)
        plot(d,'Parent',a);
    end

case 'load_protocol_callback'
    [fn pn] = uigetfile('*.mat','Load episode control data...');
    c = load([pn fn]);
    if (isfield(c,'control'))
        wc.control.episode = c.control;
        setValues(c.control);
    end
    
case 'save_protocol_callback'
    [fn pn] = uiputfile('*.mat','Save episode control data...');
    control = getValues;
    save([pn fn],'control');
    
case 'close_callback'
    delete(gcbf);
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function p = defaultParams()
global wc;

    p.output.description = 'LED channel'
    p.output.fieldtype = 'list';
    p.output.choices = GetChannelList(wc.ao);
    p.output.value = 1;
    p.s_max.description = 'Max LED Voltage';
    p.s_max.fieldtype = 'value';
    p.s_max.units = 'V';
    p.s_max.value = 3.6;
    p.s_res.description = 'Stimulus Resolution';
    p.s_res.fieldtype = 'value';
    p.s_res.value = 5;
    p.t_res.description 'Stimulus Frame Rate';
    p.t_res.fieldtype = 'value';
    p.t_res.units = 'ms';
    p.t_res.value = '100';
    
    p.input.description = 'Amplifier Channel'
    p.input.fieldtype = 'list';
    p.input.choices = GetChannelList(wc.ai);
    ic = get(wc.control.amplifier,'Index');
    p.input.value = ic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc

sr = get(wc.ai, 'SampleRate');
update = fix(sr / 20); % update at 20 Hz
set(wc.ai,'SamplesPerTrigger',inf);
set(wc.ai,'SamplesAcquiredActionCount',update);
set(wc.ai,'SamplesAcquiredAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data

t_res = GetParam(me,'t_res','value');
sr = 10 * 1000 / t_res ; % 10 samples per value (should help averaging)
%set(wc.ao, 'SampleRate', sr)
set(wc.ao,'SamplesPerTrigger',inf);
c = whitenoise(update * 3);
putdata(wc.ao, c);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wn = whitenoise(samples)
% generates quantized one-dimensional gaussian white noise
s_max = GetParam(me,'s_max','value');
s_res = GetParam(me,'s_res','value');
wn = randn(samples,1);
a = wn - min(wn);
a = round(a * s_res / max(a)) * s_max / s_res;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function scope = getScope()
scope = GetUIHandle('scope','scope');
if (isempty(scope) | ~ishandle(scope))
    Scope('init');
    scope = GetUIHandle('scope','scope');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55555
function varargout = startSweep()
% Begins a sweep
global wc;
    stop([wc.ai wc.ao]);
    putdata(wc.ao, wc.control.pulse);
    SetUIParam('scope','status','String',get(wc.ai,'logfilename'));
    start([wc.ai wc.ao]);
    trigger([wc.ai wc.ao]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupScope(scope, amp, control);
% sets up the scope properties
clearPlot(scope);
%set(scope, 'YLim', [-3 3]);
set(scope, 'XLim', [0 1000]);
set(scope, 'NextPlot', 'replacechildren');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
lbl = get(scope,'YLabel');
set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(data, time, abstime, scope, index)
% plots the data

mode = GetParam('control.telegraph', 'mode');
gain = GetParam('control.telegraph', 'gain');
if ~isempty(mode)
    units = TelegraphReader('units',mean(data(:,mode)));
else
    units = 'V';
end
if ~isempty(gain)
    gain = TelegraphReader('gain',mean(data(:,gain)));
else
    gain = 1;
end
lbl = get(scope,'YLabel');
set(lbl,'String',['amplifier (' units ')']);
% plot the data and average response
data = AutoGain(data(:,index), gain, units);
avgdata = get(scope,'UserData');
avgdata = cat(2, avgdata, data); % TODO: catch irregular sized datas
Scope('plot','plot',time * 1000, [data mean(avgdata,2)]);
set(scope,'UserData', avgdata);
EpisodeStats('plot', abstime, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
kids = get(axes, 'Children'); 
delete(kids);
set(axes,'UserData',[]);
