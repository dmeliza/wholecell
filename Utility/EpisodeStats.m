function EpisodeStats(varargin)
% The EspisodeStats is used to plot PSP/PSC statistics over the course
% of an episodic experiment.
%
%  EpisodeStats('init',tunit,yunit,statfun) - initializes the figures
%  EpisodeStats('plot',time,data) - updates plots with a new trace
%
%   statfun is a handle to a function that has the following stub:
%   value = statfun(data), where value can be an array of stats
%   or, if statsfun is a string, EpisodeStats will try to execute a function
%   defined in this file
%
% $Id$

global wc

if nargin > 0
	action = lower(varargin{1});
else
	action = 'init';
end
switch action
    
case 'init'
    
    if nargin ~= 4
        disp('EpisodeStats(''init'',tunit,yunit,abstunit,statfun)');
        return;
    end
    tunit = varargin{2};
    yunit = varargin{3};
    statsfun = varargin{4};
    
    fig_timecourse = InitUIObject(me,'fig_timecourse','figure',...
        'NumberTitle','off','Name','stats: Time Course',...
        'menubar','none','Color',get(0,'defaultUicontrolBackgroundColor'),...
        'doublebuffer','on','Position',[289    45   800   239]);
    zoom(fig_timecourse,'on');
    timecourse = InitUIObject(me,'timecourse','axes','NextPlot','add');
    set(timecourse,'UserData',statsfun);
    xlabel(tunit);
    ylabel(yunit);
    
case 'plot'
    if nargin ~= 3
        return;
    end
    time = varargin{2};
    data = varargin{3};
    
    % update statistics
    ah = GetUIHandle(me,'timecourse');
    % time may be in a clock format, so we have to convert it
    if length(time) > 1
        time = convertTime(ah, time);
    end
    fun = get(ah,'UserData');
    try
        val = feval(fun,data);
        axes(ah);
        plot(time, val, 'o');
    catch
        disp(lasterr);
    end
    
case 'clear'
    kids = GetUIParam(me,'timecourse','Children');
    delete(kids(find(ishandle(kids))));
    xlabel = GetUIParam(me,'timecourse','Xlabel');
    set(xlabel,'UserData',[]);
    
case 'destroy'
    figs = [GetUIHandle(me,'fig_timecourse')];
    delete(figs(find(ishandle(figs))));
    if (~isfield(wc, me))
        wc = rmfield(wc, me);
    end
    
otherwise
    disp([action ' is not supported.']);
end

%%%%%%%%%%%%%functions
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%55
function realtime = convertTime(graphhandle, clockvector)
xlabel = get(graphhandle,'Xlabel');
start = get(xlabel,'UserData');
if isempty(start)
    set(xlabel,'UserData',clockvector);
    realtime = 0;
else
    time = clockvector - start;
    realtime = time(:,4)*60 + time(:,5) + time(:,6)/60;
end


%%%%%%%%%%%%%%%%
function val = Vm(data)
% just reports the resting potential
val = mean(data);

%%%%%%%%%%%%%%%%%%
function val = peakPSR(data)
% attempts to figure out the peak PSR value following the stimulus
% artifact
d = diff(data);
[y i] = max(d); % artifact should be the fastest thing here
if i > 1000 & i < length(data) - 1500
    baseline = mean(data(i-1000:i-800));
    peak = max(abs(data(i+40:i+1500) - baseline));
    val = peak;
else
    val = max(abs(data - mean(data)));
end

%%%%%%%%%%%%%%%%%%%%%
function val = inputResist(data)
% a cheapy little input resist measurement.  Finds the minimum
% slope after 500 ms and then measures a difference between 50 ms before
% and after
offset = 5000;
d = diff(data);
[y i] = min(d(offset:length(d)));
offset = offset + i;
if offset > 1000 & offset < length(data) - 1500
    baseline = mean(data(offset-1000:offset-50));
    peak = mean(data(offset+50:offset+1000));
    val = peak - baseline;
else
    val = 0;
end

%%%%%%%%%%%%%%%%%%%5
function val = PSR_IR(data)
% returns both peak and IR
val = [peakPSR(data) inputResist(data)];