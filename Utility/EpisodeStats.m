function EpisodeStats(varargin)
% The EspisodeStats is used to plot PSP/PSC statistics over the course
% of an episodic experiment. It generates two figures which contain
% the time-averaged data and the time course.
%
%  EpisodeStats('init',tunit,yunit,abstunit,statfun) - initializes the figures
%  EpisodeStats('plot',time,data,abstime) - updates plots with a new trace
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
    
    if nargin ~= 5
        disp('EpisodeStats(''init'',tunit,yunit,abstunit,statfun)');
        return;
    end
    tunit = varargin{2};
    yunit = varargin{3};
    abstunit = varargin{4};
    statsfun = varargin{5};

    fig_average = InitUIObject(me,'fig_average','figure',...
        'NumberTitle','off','Name','stats: Average Response',...
        'menubar','none','Color',get(0,'defaultUicontrolBackgroundColor'),...
        'Position', [289    43   452   241]);
    zoom(fig_average,'on');
    average = InitUIObject(me,'average','axes','NextPlot','replacechildren');
    xlabel(tunit);
    ylabel(yunit);
    
    fig_timecourse = InitUIObject(me,'fig_timecourse','figure',...
        'NumberTitle','off','Name','stats: Time Course',...
        'menubar','none','Color',get(0,'defaultUicontrolBackgroundColor'),...
        'Position',[750    45   451   239]);
    zoom(fig_timecourse,'on');
    timecourse = InitUIObject(me,'timecourse','axes','NextPlot','add');
    set(timecourse,'UserData',statsfun);
    xlabel(abstunit);
    ylabel(yunit);
    
case 'plot'
    if nargin ~= 4
        return;
    end
    time = varargin{2};
    data = varargin{3};
    abstime = varargin{4};
    
    % first update response average
    ah = GetUIHandle(me,'average');
    mydata = get(ah,'UserData');
    mydata = cat(2, mydata, data); % TODO: catch irregular sized datas
    plot(time, mean(mydata,2), 'Parent', ah);
    set(ah,'UserData',mydata);
    
    % update statistics
    ah = GetUIHandle(me,'timecourse');
    fun = get(ah,'UserData');
    try
        val = feval(fun,data);
        axes(ah);
        plot(abstime, val, 'o');
    catch
        disp(lasterr);
    end
    
case 'clear'
    SetUIParam(me,'average','UserData',[]);
    kids = GetUIParam(me,'average','Children');
    delete(kids(find(ishandle(kids))));
    kids = GetUIParam(me,'timecourse','Children');
    delete(kids(find(ishandle(kids))));
    
case 'destroy'
    figs = [GetUIHandle(me,'fig_average') GetUIHandle(me,'fig_timecourse')];
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

%%%%%%%%%%%%%%%5
function val = Vm(data)
% just reports the resting potential
val = [mean(data) std(data)];
