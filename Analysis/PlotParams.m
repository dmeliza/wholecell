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