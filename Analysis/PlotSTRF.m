function f = PlotSTRF(strf)
% 
% PlotSTRF plots STRFs (or a series of linked STRFs) in a nice window with some
% useful functionality.  Each STRF is plotted in its own axis and the colormap
% is scaled so that zero is at the middle of the CLUT.  A slider is provided
% below the graphs for changing frame, and when the user double-clicks on a pixel
% in the image, a separate window is opened with the time-course of the pixel
%
% Usage:   f = PlotSTRF(strf)
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

% find the absolute maximum of all the STRFs
for i = 1:NUM
    mx(i)    = max(max(max(abs(strf(i).data))));
end
mx           = max(mx);

% make plots
for i = 1:NUM
    subplot(1,NUM,i)
    [X Y T] = size(strf(i).data);
    if X == 1 & Y == 1
        h   = plot(squeeze(strf(i).data))                 % single pixel STRF, use plot
        set(gca,'YLim',[-mx mx]);
    else
        Z   = interpolate(strf(i).data(:,:,1));
        h   = imagesc(Z,[-mx mx]);
        text(1,1,getTime(1));
        set(h,'buttondownfcn',click)
        set(gca,'UserData',strf(i).data,'NextPlot','replacechildren',...
            'XTick',[],'YTick',[]);
        if isfield(strf(i),'title')
            title(strf(i).title);
        end
    end
    m = makemenu;
    set(gca,'UiContextMenu',m);
    set(h,'UiContextMenu',m);

end

% setup slider
if X == 1 & Y == 1
    % do nothing
else
    colormap(gray)
    step     = 1/(T-1);
    h        = uicontrol('style','slider','position',[45 5 dim(1)-90 20],...
        'Min',1,'Max',T,'SliderStep',[step step],'Value',1,...
        'Callback',cb,'tag','slider','UserData',1);
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

function m = makemenu()
% Generates the context menu
colmaps   = {'gray','hot','hsv','pink','cool','bone','prism'};
interps   = [1 2 5 10];
colmap_cb = @changeColormap;
interp_cb = @changeInterpolation;
exp       = @exportSTRF;

m = uicontextmenu;
h = uimenu(m,'Label','Colormap');
for i = 1:length(colmaps)
    l(i) = uimenu(h,'Label',colmaps{i},'Callback',colmap_cb);
end
set(l(1),'Checked','On');
h = uimenu(m,'Label','Interpolate');
for i = 1:length(interps)
    l(i) = uimenu(h,'Label',num2str(interps(i)),'Callback',interp_cb);
end
set(l(1),'Checked','On');
uimenu(m,'Label','Export','Callback',{exp,gca});

function Z = interpolate(data)
% uses interp2 to interpolate (smooth) a dataset
% if data is 1-dimensional, this should not be called
h  = findobj(gcf,'tag','slider');
lvl = get(h,'UserData');
if lvl == 1 | isempty(lvl)
    Z = data;
else
    [x y] = size(data);             % "real" indices are 0 to x-1 (y-1)
    xi = linspace(0,x-1,x*lvl);
    yi = linspace(0,y-1,y*lvl);
    [X Y] = meshgrid(xi,yi);
    Z  = interp2(0:x-1,0:y-1,data,X,Y);     % could use a cubic interpolator here...
end

function [] = replot()
% replots all the axes in the window
click   = @clickSTRF;
obj     = findobj(gcf,'tag','slider');
val     = fix(get(obj,'Value'));
f       = get(obj,'Parent');
a       = findobj(f,'type','axes'); % the axes in the window
for i = 1:length(a)
    axes(a(i))
    R   = get(a(i),'UserData');
    mx  = get(a(i),'CLim');         % keep the CLUT axis the same
    R   = interpolate(R(:,:,val));
    h   = imagesc(R,mx);
    set(h,'buttondownfcn',click);
    set(h,'UiContextMenu',get(a(i),'UiContextMenu'));
    text(1,1,getTime(val))
end
axis(a,'tight')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callbacks:

function [] = moveSlider(obj, event)
% handles slider position changes
replot;

function [] = changeColormap(obj, event)
% changes colormap of figure
sel = get(obj,'Label');     % name of colmap
colormap(sel);
par = get(obj,'Parent');
kid = get(par,'Children');
set(kid,'Checked','Off');
set(obj,'Checked','On');

function [] = changeInterpolation(obj, event)
% changes the interpolation level at which things are plotted (figure-wide)
sel = get(obj,'Label');
sli = findobj(gcf,'tag','slider');
set(sli,'UserData',str2num(sel));
par = get(obj,'Parent');
kid = get(par,'Children');
set(kid,'Checked','Off');
set(obj,'Checked','On');
replot;

function [] = clickSTRF(obj,event)
% handles double clicks on STRF pixels
type    = get(gcf,'selectiontype');
if strcmpi(type,'open');
    a       = get(obj,'Parent');                % axes
    pos     = round(get(a,'CurrentPoint'));     % position
    pos     = [pos(1,2) pos(1,1)];              % convert to matrix indices
    r       = get(a,'UserData');                % STRF
    frate   = get(gcf,'UserData');              % frame rate, if there is one
    mx      = get(a,'CLim');
    
    figure
    movegui(gcf,'southeast')
    s       = sprintf('Pixel [%d %d]',pos);     % pixel ID
    set(gcf,'color',[1 1 1],'name',s,'NumberTitle','off');
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
        
    set(gca,'YLim',mx,'YTick',[0]);
end

function [] = exportSTRF(obj,event,handle)
% handles export commands
strf = get(handle,'UserData');
if isempty(strf)
    errordlg('No data stored in object!');
    error('Unable to retreive STRF');
end
[fn pn] = uiputfile('*.mat');
if isnumeric(fn)
    return
end
save(fullfile(pn,fn),'strf');
fprintf('STRF written to file %s\n', fn);
