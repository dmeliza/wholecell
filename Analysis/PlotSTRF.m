function [] = PlotSTRF(strf)
% 
% PlotSTRF plots STRFs (or a series of linked STRFs) in a nice window with some
% useful functionality.  Each STRF is plotted in its own axis and the colormap
% is scaled so that zero is at the middle of the CLUT.  A slider is provided
% below the graphs for changing frame, and when the user double-clicks on a pixel
% in the image, a separate window is opened with the time-course of the pixel
%
% Usage:   [] = PlotSTRF(strf,)
%
%
% strf   - a structure array with the following fields:
%          .data    - MxNxP array (X,Y, and T dimensions)
%          [.title]   - the name of the strf (e.g. ON or OFF)
%          [.frate] - frame rate (in Hz).  If supplied, time units will be in seconds instead
%                     of frames.  Only strf(1).frate is used.
%
%
% $Id$

% check arguments
error(nargchk(1,1,nargin))
if ~isa(strf,'struct')
    error('Input must be a structure.')
end
if ~isfield(strf,'data')
    error('Input structure requires data field');
end

% open figure
NUM     = length(strf);     % number of STRFs to plot
dim     = [280 * NUM, 285];
cb      = @moveSlider;
click   = @clickSTRF;
f       = figure;
pos     = get(gcf,'Position');
set(gcf,'Color',[1 1 1],'Position',[pos(1) pos(2) dim(1) dim(2)],...
    'Name','STRF','Numbertitle','off');
if isfield(strf,'frate')
    set(gcf,'UserData',strf(1).frate);
end

% make plots
for i = 1:NUM
    subplot(1,NUM,i)
    mx      = max(max(max(abs(strf(i).data))));     % absolute maximum of STRF
    [X Y T] = size(strf(i).data);
    if X == 1 & Y == 1
        plot(squeeze(strf(i).data))                 % single pixel STRF, use plot
        set(gca,'YLim',[-mx mx]);
    else
        h   = imagesc(strf(i).data(:,:,1),[-mx mx]);
        text(1,1,getTime(1));
        set(h,'buttondownfcn',click)
        set(gca,'UserData',strf(i).data,'NextPlot','replacechildren',...
            'XTick',[],'YTick',[]);
        if isfield(strf(i),'title')
            title(strf(i).title);
        end
    end
end

% setup slider
if X == 1 & Y == 1
    % do nothing
else
    colormap(gray)
    step     = 1/(T-1);
    h        = uicontrol('style','slider','position',[45 5 490 20],...
        'Min',1,'Max',T,'SliderStep',[step step],'Value',1,...
        'Callback',cb);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals:

function str = getTime(ind)
% If there is a frame rate, convert index into time
% Otherwise return the index
frate       = get(gcf,'UserData');
if isempty(frate)
    str = num2str(ind);
else
    str = num2str((ind-1)/frate);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:

function [] = moveSlider(obj, event)
% handles slider position changes
click   = @clickSTRF;
val     = fix(get(obj,'Value'));
f       = get(obj,'Parent');
a       = findobj(f,'type','axes'); % the axes in the window
for i = 1:length(a)
    axes(a(i))
    R   = get(a(i),'UserData');
    mx  = max(max(max(abs(R))));
    h   = imagesc(R(:,:,val),[-mx mx]);
    set(h,'buttondownfcn',click);
    text(1,1,getTime(val))
end

function [] = clickSTRF(obj,event)
% handles double clicks on STRF pixels
type    = get(gcf,'selectiontype');
if strcmpi(type,'open');
    a       = get(obj,'Parent');                % axes
    pos     = round(get(a,'CurrentPoint'));     % position
    pos     = [pos(1,2) pos(1,1)];              % convert to matrix indices
    r       = get(a,'UserData');                % STRF
    frate   = get(gcf,'UserData');              % frame rate, if there is one
    
    figure
    movegui(gcf,'southeast')
    s       = sprintf('Pixel [%d %d]',pos);     % pixel ID
    set(gcf,'color',[1 1 1],'name',s,'NumberTitle','off');
    mx      = max(max(max(abs(r))));            % scale all responses to absolute max
    Y       = squeeze(r(pos(1),pos(2),:));      % our response
    x_mean  = squeeze(mean(mean(r,1),2));       % the "energy" of the STRF through time
    if isempty(frate)
        T   = 1:length(Y);
        str = 'Frame';
    else
        T   = 0:1/frate:(length(Y)-1)/frate;
        str = 'Time (s)';
    end
    plot(T,Y,'-k','LineWidth',2)
    hold on
    plot(T,x_mean,':k');
    xlabel(str);
        
    set(gca,'YLim',[-mx mx],'YTick',[0]);
end