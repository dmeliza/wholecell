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
    setupScope;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    SetUIParam('scope','status','String','Not recording');
    queueStimulus;
    pause(1);
    StartAcquisition(me,[wc.ai wc.ao]);
    
case 'record'
    switch get(wc.ai,'Running')
    case 'On'
        feval(me,'stop');
    end
    setupHardware;
    setupScope;
    SetUIParam('wholecell','status','String',get(wc.ai,'Running'));
    %SetUIParam('scope','status','String',['Sweeps Acquired: 0']);
    % data is stored in a directory, one file per sweep.
    set(wc.ai,{'LoggingMode','LogToDiskMode'}, {'Disk&Memory','Overwrite'});
    lf = NextDataFile;
    set(wc.ai,'LogFileName',lf);
    SetUIParam('scope','status','String',lf);
    queueStimulus;
    StartAcquisition(me,[wc.ai wc.ao]);
    
case 'stop'
    stop([wc.ai wc.ao]);
    if (isvalid(wc.ai))
        set(wc.ai,'SamplesAcquiredAction','');
        SetUIParam('wholecell','status','String',get(wc.ai,'Running'));        
        set(wc.ai,'LoggingMode','Memory');
    end

case 'sweep'
    data = varargin{2};
    time = varargin{3};
    abstime = varargin{4};
    queueStimulus;
    plotData(data, time, abstime, getScope, wc.control.amplifier.Index);
    
otherwise
    disp(['Action ' action ' is unsupported by ' me]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function p = defaultParams()
global wc;

    p.output.description = 'LED channel';
    p.output.fieldtype = 'list';
    p.output.choices = GetChannelList(wc.ao);
    p.output.value = 1;
    p.s_max.description = 'Max LED Voltage';
    p.s_max.fieldtype = 'value';
    p.s_max.units = 'V';
    p.s_max.value = 3.6;
    p.s_min.description = 'Min LED Voltage';
    p.s_min.fieldtype = 'value';
    p.s_min.units = 'V';
    p.s_min.value = 2.0;
    p.s_res.description = 'Stim Res';
    p.s_res.fieldtype = 'value';
    p.s_res.value = 5;
    p.t_res.description = 'Frame Rate';
    p.t_res.fieldtype = 'value';
    p.t_res.units = 'ms';
    p.t_res.value = 100;
    
    p.input.description = 'Amplifier Channel';
    p.input.fieldtype = 'list';
    p.input.choices = GetChannelList(wc.ai);
    ic = get(wc.control.amplifier,'Index');
    p.input.value = ic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupHardware()
% Sets up the hardware for this mode of acquisition
global wc

sr = get(wc.ai, 'SampleRate');
update = fix(sr / 2); % update at 20 Hz
set(wc.ai,'SamplesPerTrigger',inf);
set(wc.ai,'SamplesAcquiredActionCount',update);
set(wc.ai,'SamplesAcquiredAction',{'SweepAcquired',me}) % calls SweepAcquired m-file, which deals with data
set(wc.ai,'UserData',update);

t_res = GetParam(me,'t_res','value');
sr = 1000 / t_res ; % 10 samples per value (should help averaging)
set(wc.ao, 'SampleRate', sr)
%set(wc.ao,'SamplesPerTrigger',inf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wn = whitenoise(samples)
% generates quantized one-dimensional gaussian white noise
s_max = GetParam(me,'s_max','value');
s_min = GetParam(me,'s_min','value');
s_res = GetParam(me,'s_res','value');
wn = randn(samples,1);
wn = wn - min(wn);
wn = round(wn * s_res / max(wn)) * (s_max - s_min) / s_res + s_min;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
function queueStimulus(varargin)
% queues data in the ao object and records it to a param in wc
global wc
if nargin > 0
    m = varargin{1};
else
    m = 1;
end
update = get(wc.ai,'Samplesacquiredactioncount');
control = GetParam(me,'output','value');
c = zeros(update * m, length(wc.ao.Channel));
c(:,control) = whitenoise(update * m);
putdata(wc.ao, c);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function scope = getScope()
scope = GetUIHandle('scope','scope');
if (isempty(scope) | ~ishandle(scope))
    Scope('init');
    scope = GetUIHandle('scope','scope');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = setupScope(scope, amp);
% sets up the scope properties
scope = getScope;
clearPlot(scope);
%set(scope, 'YLim', [-3 3]);
set(scope, 'XLim', [0 1000]);
set(scope, 'NextPlot', 'add');
lbl = get(scope,'XLabel');
set(lbl,'String','Time (ms)');
% lbl = get(scope,'YLabel');
% set(lbl,'String',[get(amp, 'ChannelName') ' (' get(amp,'Units') ')']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = plotData(data, time, abstime, scope, index)
% plots the data

data = data(:,index);
%time = time - time(1);
Scope('scroll',time * 1000, data);
% mode = GetParam('control.telegraph', 'mode');
% gain = GetParam('control.telegraph', 'gain');
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
% data = AutoGain(data(:,index), gain, units);
% avgdata = get(scope,'UserData');
% avgdata = cat(2, avgdata, data); % TODO: catch irregular sized datas
% Scope('plot','plot',time * 1000, [data mean(avgdata,2)]);
% set(scope,'UserData', avgdata);
% EpisodeStats('plot', abstime, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function clearPlot(axes)
kids = get(axes, 'Children'); 
delete(kids);
