function [] = PlotParams(ptf)
% 
% PlotParams plots param temporal functions (PTF) (or a series of linked PTFs) 
% in a nice window with some useful functionality.  Each PTF is plotted in its
% own axis and the colormap is scaled so that zero is at the middle of the CLUT.  
% When the user double-clicks on a row in the image, a separate window is opened 
% with the time-course of the param
%
% Usage:   [] = PlotParams(ptf)
%
%
% strf   - a structure array with the following fields:
%          .data    - MxP array (param and time dimensions)
%          [.title] - the name of the PTF (e.g. ON or OFF)
%          [.frate] - frame rate (in Hz).  If supplied, time units will be in seconds instead
%                     of frames.  Only ptf(1).frate is used.
%          [.cb]    - if this function handle (or cell array) is supplied,
%                     it will be called instead of the default callback for row clicks
%
%
% $Id$

% check arguments
error(nargchk(1,1,nargin))
if ~isa(ptf,'struct')
    error('Input must be a structure.')
end
if ~isfield(ptf,'data')
    error('Input structure requires data field');
end

% open figure
NUM     = length(ptf);     % number of STRFs to plot
dim     = [280 * NUM, 420];
cb      = @clickRow;
f       = figure;
pos     = get(gcf,'Position');
set(gcf,'Color',[1 1 1],'Position',[pos(1) pos(2) dim(1) dim(2)],...
    'Name','PTRF','Numbertitle','off');    
% if isfield(ptf,'frate')
%     set(gcf,'UserData',ptf(1).frate);
% end

% make plots
for i = 1:NUM
    subplot(1,NUM,i)
    mx      = max(max(max(abs(ptf(i).data))));     % absolute maximum of PTF
    [P T]   = size(ptf(i).data);
    p       = 1:P;
    if isfield(ptf(i), 'frate')
        t   = 0:1/ptf(i).frate:(T-1)/ptf(i).frate;
        str = 'Time (s)';
    else
        t   = 1:T;
        str = 'Frames';
    end
    if P == 1
        plot(t,squeeze(ptf(i).data))                 % single param, use plot
        xlabel(str);
        set(gca,'YLim',[-mx mx]);
    else
        h   = imagesc(t,p,ptf(i).data,[-mx mx]);     % multiple params, use imagesc
        xlabel(str)
        ylabel('Parameter')
        if isfield(ptf(i), 'cb')
            set(h,'buttondownfcn',ptf(i).cb)
        else
            set(h,'buttondownfcn',cb)
        end
    end
    if isfield(ptf(i),'title')
        title(ptf(i).title);
    end
    m = makemenu;
    set(gca,'UiContextMenu',m);
    set(h,'UiContextMenu',m);
end
colormap(gray)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:

function [] = clickRow(obj,event)
% handles double clicks on STRF pixels
type    = get(gcf,'selectiontype');
if strcmpi(type,'open');
    % locate the click
    a       = get(obj,'Parent');                % axes
    Y       = round(get(a,'CurrentPoint'));     % position
    y       = round(Y(1,2));                    % convert to matrix index
    r       = get(obj,'CData');                 % PTF
    lim     = get(obj,'XData');                 % time vector
    mx      = max(max(r));
    % draw a line
    h       = findobj(gcf,'type','line');
    delete(h);
    line([lim(1) lim(end)],[y y]);
    % look up the parameter
    resp    = r(y,:);
    figure
    movegui(gcf,'southeast')
    str     = ['Parameter ' num2str(y)];
    set(gcf,'color',[1 1 1],'name',str,'NumberTitle','off');
    if length(lim) > 2
        plot(lim,resp','-k')
        xlabel('Time (s)')
    else
        plot(resp','-k')
        xlabel('Frame')
    end
    set(gca,'YLim',[-mx mx]);
    title(str);    
end

function m = makemenu()
% Generates the context menu
colmaps   = {'gray','jet','hot','hsv','pink','cool','bone','prism'};
colmap_cb = @changeColormap;
exp       = @exportSTRF;
ref       = @reshapeParams;
m = uicontextmenu;
h = uimenu(m,'Label','Colormap');
for i = 1:length(colmaps)
    l(i) = uimenu(h,'Label',colmaps{i},'Callback',colmap_cb);
end
set(l(1),'Checked','On');
uimenu(m,'Label','Reshape','Callback',{ref,gca});
uimenu(m,'Label','Export','Callback',{exp,gca});

function [] = changeColormap(obj, event)
% changes colormap of figure
sel = get(obj,'Label');     % name of colmap
colormap(sel);
par = get(obj,'Parent');
kid = get(par,'Children');
set(kid,'Checked','Off');
set(obj,'Checked','On');

function [] = exportSTRF(obj,event,handle)
% handles export commands
c    = findobj(handle,'Type','image');
if isempty(c)
    errordlg('No data stored in object!');
    error('Unable to retreive parameter response');
end
param = get(c,'CData');
[fn pn] = uiputfile('*.mat');
if isnumeric(fn)
    return
end
save(fullfile(pn,fn),'param');
fprintf('Params written to file %s\n', fn);

function [] = reshapeParams(obj, event, handle)
% Tries to reshape the PTRF into a three dimensional
% response function.  This is most likely to be useful with
% something like a hartley grating basis set where the
% responses to wave numbers should be meaningful. It tries
% to find the matrix which is closest to square to reshape
% into
c    = findobj(handle,'Type','image');
if isempty(c)
    errordlg('No data stored in object!');
    error('Unable to retreive parameter response');
end
param = get(c,'CData');
time  = get(c,'XData');
[m n] = size(param);
% this is cool:
x = max(factor(m));           % largest integral factor
y = m/x;                      % has to be an integer!
strf = reshape(param,x,y,n);
strf = permute(strf,[2 1 3]);   % this is a hack for use with the parameters for hartley bs
map = colormap;
PlotSTRF(struct('data',strf,'frate',1/mean(diff(time))));
colormap(map);