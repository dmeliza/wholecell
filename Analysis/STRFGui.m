function [] = STRFGui()
%
% The all-in-one GUI for analyzing stimulus/response data.  Opens a GUI
% which allows the user to pick a stimulus file, and some response files (either
% .daq files or a .mat file).  Once these are picked, the user can view the stimulus,
% analyze the responses for stationarity, and analyze the data using parameterization
% or PCA to get STRFs.
%
% $Id$

error(nargchk(0,0,nargin))

initFigure;
initValues;

function initValues()
% sets initial values
methods = {'Xcorr','Sparse','PCA'};
filters = {'None','Highpass','Lowpass'};
SetUIParam(me,'directory','String',pwd);
updateLists;
SetUIParam(me,'stimulusstatus','String','No stimulus loaded.');
SetUIParam(me,'responsestatus','String','No responses loaded.');
SetUIParam(me,'filter','String',filters);
SetUIParam(me,'filter_param','String','0.5');
SetUIParam(me,'method','String',methods);
SetUIParam(me,'binfactor','String','1');
SetUIParam(me,'analysisframes','String','5');

function initFigure()
% opens the figure
cb = getCallbacks;
BG = [1 1 1];
f = OpenFigure(me,'position',[360   343   700   600],...
    'color',BG,'menubar','none');
movegui(f,'northeast');
% Frame 1: file operations
h = uicontrol(gcf, 'style', 'frame','backgroundcolor',BG,'position',[15 390 450 200]);
% text
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[21 560 60 20],...
    'String','Directory:');
h = InitUIControl(me, 'directory','style','text',...
    'backgroundcolor',BG,'position',[80 560 350 20]);
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[20 540 60 20],...
    'String','Stimulus:');
h = uicontrol(gcf, 'style','text','backgroundcolor',BG,'position',[240 540 60 20],...
    'String','Response:');
% list boxes
h = InitUIControl(me, 'stimulus', 'style','list',...
    'Callback',cb.pickstimulus,...
    'position', [25 440 200 100],'backgroundcolor',BG);
h = InitUIControl(me, 'response', 'style','list',...
    'Callback',cb.pickresponse,...
    'position', [245 440 200 100],'backgroundcolor',BG,'Max',2);
% push buttons
h = InitUIControl(me, 'playstimulus', 'style', 'pushbutton',...
    'callback',cb.playstimulus,...
    'position', [25 415 60 20], 'String', 'Play');
h = InitUIControl(me, 'showstimulus', 'style', 'pushbutton',...
    'callback',cb.showstimulus,...
    'position', [90 415 60 20], 'String', 'Show');
h = InitUiControl(me, 'showresponse', 'style', 'pushbutton',...
    'callback',cb.showresponse,...
    'position', [250 415 60 20], 'String', 'Show');
h = InitUiControl(me, 'xcorrresponse', 'style', 'pushbutton',...
    'callback',cb.xcorrresponse,...
    'position', [320 415 60 20], 'String', 'XCorr');
h = InitUIControl(me, 'combineresponse','style','pushbutton',...
    'callback',cb.combineresponse,...
    'position', [390 415 60 20], 'String', 'Save');
% Frame 2: stimulus operations
h  = InitUIObject(me, 'stimulusaxes', 'axes', 'units','pixels','position',[30 40 340 340],...
    'nextplot','replacechildren','XTick',[],'Ytick',[],'Box','On');
h  = InitUIObject(me, 'clut', 'axes', 'units', 'pixels', 'position', [400 60 30 300],...
    'nextplot','replacechildren','XTick',[],'YTick',[],'Box','On');
% Frame 3: status
h = uicontrol(gcf,'style','frame','backgroundcolor',BG,'position',[470 390 220 200]);
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 560 80 20],...
    'String','Stimulus','horizontalalignment','left','Fontsize',10,'fontweight','bold');
h = InitUiControl(me, 'stimulusstatus', 'style', 'text', 'backgroundcolor',BG,...
    'position',[480 490 200 70],'horizontalalignment','left');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 470 80 20],...
    'String','Response','horizontalalignment','left','Fontsize',10,'fontweight','bold');
h = InitUIControl(me, 'responsestatus', 'style', 'text', 'backgroundcolor',BG,...
    'position',[480 400 200 70],'horizontalalignment','left');
% Frame 4: analysis
h = uicontrol(gcf,'style','frame','backgroundcolor',BG,'position',[470 40 220 340]);
% static text
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 350 70 20],...
    'String','Analysis','horizontalalignment','left','Fontsize',10,'fontweight','bold');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 325 60 20],...
    'String','Window:','horizontalalignment','left');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 305 60 20],...
    'String','Bin Factor:','horizontalalignment','left');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 285 60 20],...
    'String','Frames:','horizontalalignment','left');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 245 60 20],...
    'String','Prefilter:','horizontalalignment','left');
h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 225 60 20],...
    'String','Cutoff:','horizontalalignment','left');    

h = uicontrol(gcf,'style','text','backgroundcolor',BG,'position',[480 185 60 20],...
    'String','Method:','horizontalalignment','left');    

% 'editables'
h = InitUIControl(me,'analysiswindow','style','edit','backgroundcolor',BG,...
    'horizontalalignment','right','position',[580 328 100 20],'enable','inactive');
h = InitUIControl(me,'binfactor','style','edit','backgroundcolor',BG,...
    'horizontalalignment','right','position',[580 308 100 20]);
h = InitUIControl(me,'analysisframes','style','edit','backgroundcolor',BG,...
    'horizontalalignment','right','position',[580 288 100 20]);
h = InitUIControl(me,'filter','style','popup','backgroundcolor',BG,...
    'horizontalalignment','right','position',[580 248 100 20],'String',' ');
h = InitUIControl(me,'filter_param','style','edit','backgroundcolor',BG,...
    'horizontalalignment','right','position',[580 228 100 20],'String',' ');

h = InitUIControl(me,'method','style','popup','backgroundcolor',BG,...
    'horizontalalignment','right','position',[580 188 100 20],'String',' ');
% buttons
h = InitUIControl(me,'analyze','style','pushbutton','String','Analyze',...
    'Position',[530 100 100 20],...
    'Callback',cb.analyze);
h = InitUIControl(me,'xcorrtiming','style','pushbutton','String','XCorr Timing',...
    'Position',[530 70 100 20],...
    'Callback',cb.xcorrtiming);
% Status bar
h  = InitUIControl(me,'Status','style','text','backgroundcolor',BG,...
    'horizontalalignment','center','position',[1 1 690 20]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Callbacks
function [] = playstimulus(obj, event)
stim = GetUIParam(me,'stimulus','UserData');
if ~isempty(stim)
    PlayMovie(stim);
end

function [] = showstimulus(obj, event)
% Plots stimulus and its 2D FFT
f            = findfig('strfgui_stimulus');
set(f,'Color',[1 1 1]);
a            = axes;
stim         = GetUIParam(me,'stimulus','UserData');
[X Y FRAMES] = size(stim.stimulus);
s            = reshape(stim.stimulus,X*Y,FRAMES);
imagesc(s);
title('Stimulus')
axis(a,'tight');
xlabel('Frame')
ylabel('Parameter');
colormap(stim.colmap);

function [] = showresponse(obj, event)
resp   = loadResponse;
r      = struct2array(resp,'data','pad');
figure,mtrialplot(r);

function [] = xcorrresponse(obj, event)
resp   = loadResponse;
if length(resp) == 1
    setstatus('Data does not contain any repeats');
    return
end
r      = struct2array(resp,'data','drop');
time   = struct2array(resp,'timing','drop');
frate  = fix(mean(mean(diff(time))));
data   = bindata(r,frate,1);
corr_repeats(data);

function [] = xcorrtiming(obj,event)
resp   = loadResponse;
if length(resp) == 1
    setstatus('Data does not contain any repeats.');
    return
end
time        = struct2array(resp,'timing','drop');
corr_repeats(diff(time));

    
function [] = combineresponse(obj, event)
[fn pn] = uiputfile('*.r1');
if isa(fn,'char')
    r1      = loadResponse;
    save(fullfile(pn,fn),'r1','-mat');
    setstatus(['Saved response as ' fullfile(pn,fn)]);
    updateLists;
end
    
function [] = pickstimulus(obj, event)
% double click: change directory
% single click: select stimulus
sel     = get(gcf,'SelectionType');
wd      = GetUIParam(me,'directory','String');
choice  = GetUIParam(me,'stimulus','selected');    
if strcmpi(sel,'open')
    if choice(end)=='/'
        curr = pwd;
        cd(wd);
        cd(choice);
        SetUIParam(me,'directory','String',pwd);
        cd(curr);
        updateLists;
    end
else
    if ~(choice(end)=='/')
        loadStimulus([wd filesep choice]);
    end
end    

function [] = pickresponse(obj, event)
% selection causes the GUI to load information about the responses
wd     = GetUIParam(me,'directory','String');    % working directory
choice = GetUIParam(me,'response','selected');   % selected responses
n      = size(choice,1);                         % number of selections
str    = '';                                     % output string
for  i = 1:n
    [pn fn ext] = fileparts([wd filesep deblank(choice(i,:))]);
    switch lower(ext)
    case '.daq'
        inf     = GetDAQHeader(fullfile(pn,[fn ext]));
        str     = sprintf('%s%s: %d x %d x 1\n',...
                          str, choice(i,:), inf.samples, size(inf.channels,2));
    case '.r1'
        [d,s]   = LoadResponseFile(fullfile(pn,[fn ext]));
        str     = sprintf('%s%s: %s', str, [fn ext], s);
    otherwise
        str     = sprintf('%s%s: invalid file\n', str, [fn ext]);
    end
    % not enough room for more than 5 lines, no sense in running the loop any more
    if i >= 5, break, end
end
SetUIParam(me,'responsestatus','String',str);

function [] = pickregion(obj, event)
% lets user drag a rectangle over the graph to select a region of the stimulus to analyze
button = get(gcf,'selectiontype');
if strcmpi(button,'normal')
    x = rbbox;
    drawLines(obj, x);
elseif strcmpi(button,'alt')
    drawLines(obj);
end

function [] = analyze(obj,event)
% this function takes responsibility for conditioning the data for the analysis fxns
% the "adaptor" GUIs are responsible for displaying the data in a useful format.
stim    = GetUIParam(me,'stimulus','UserData');
resp    = loadResponse;
win     = str2num(GetUIParam(me,'analysiswindow','String'));
bin     = GetUIParam(me,'binfactor','StringVal');
m       = GetUIParam(me,'method','Selected');
lags    = GetUIParam(me,'analysisframes','StringVal');
repeats = length(resp);
frate   = mean(diff(resp(1).timing));
setpref('strfGUI','frate',frate);                       % this is used to set time units elsewhere
binrate = fix(bin * frate);
if binrate == 0
    binrate = 1;
end
setpref('strfGUI','srate',resp(1).t_rate / binrate);   % this is used to set time units elsewhere
if isempty(stim)
    setstatus('Analysis failed: No stimulus selected');
elseif isempty(resp)
    setstatus('Analysis failed: No response selected');
% elseif ~exist(m)
%     setstatus('Analysis failed: Could not find mfile');
else
    switch lower(m)
    case 'sparse'
        if ~isfield(stim,'parameters')
            setstatus('Analysis failed: Sparse Analysis requires parameterized stimulus');
        else
            SparseAnalysis(stim,resp, fix(lags * frate), fix(bin * frate));
        end
    case 'pca'
        stim = stimuluswindow(stim,win);
        PCA_2D(stim, resp, lags);
    case 'xcorr'
        stim = stimuluswindow(stim,win);
        PCA_2D(stim, resp, lags,'xcorr');
    otherwise
        setstatus('Analysis failed: adaptor has not been written for this analysis method.');
    end
end

function s = stimuluswindow(s,window)
s.stimulus = s.stimulus(window(2,1):window(2,2),window(1,1):window(1,2),:);
% s.x_res    = diff(window(1,:));
% s.y_res    = diff(window(2,:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal functions
function updateLists()
wd = GetUIParam(me,'directory','String');
% stimulus:
opt = GetDirectory(wd,'*.s0','dirs');
SetUIParam(me,'stimulus','String',opt);
SetUIParam(me,'stimulus','Value',1);
% response:
opt     = GetDirectory(wd,{'*.r1','*.daq'});
SetUIParam(me,'response','String',opt);
SetUIParam(me,'response','Value',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function stim = loadStimulus(path)
% Loads a stimulus, displaying its properties and first frame
[stim, str] = LoadStimulusFile(path);
SetUIParam(me,'stimulusstatus','String',str);
SetUIParam(me,'stimulus','UserData',stim);
if ~isempty(stim)
    plotStimulus(stim)
end

function resp = loadResponse()
% Loads responses from daq or .r1 files
% Now includes prefiltering
path        = GetUIParam(me,'directory','String');    % working directory
files       = GetUIParam(me,'response','selected');   % selected responses
path        = [path filesep];
fqp         = cat(2,repmat(path,size(files,1),1),files);
[resp, str] = CombineFiles('r1',deblank(cellstr(fqp)),[1 4]); % this is a fudge, need to get channel indices somewhere
filter      = GetUIParam(me,'filter','selected');   % selected filter
switch lower(filter)
case 'highpass'
    param     = GetUIParam(me,'filter_param','stringval');
    for i = 1:length(resp)
        param         = GetUIParam(me,'filter_param','stringval');
        resp(i).data  = HighPass(double(resp(i).data), param, resp(i).t_rate);
    end
case 'lowpass'
    param     = GetUIParam(me,'filter_param','stringval');
    for i = 1:length(resp)
        param         = GetUIParam(me,'filter_param','stringval');
        resp(i).data  = LowPass(double(resp(i).data), param, resp(i).t_rate);
    end    
end
setstatus(str);


function out = getCallbacks()
% returns a structure with function handles to functions in this mfile
% no introspection in matlab so we have to do this by hand
fns = {'playstimulus','showstimulus','showresponse','xcorrresponse',...
        'pickstimulus', 'pickresponse','combineresponse','pickregion'...
        'analyze','xcorrtiming'};
out = [];
for i = 1:length(fns)
    sf = sprintf('out.%s = @%s;',fns{i},fns{i});
    eval(sf);
end

function [] = plotStimulus(stim)
    cb      = @pickregion;
    a       = GetUIHandle(me,'stimulusaxes');
    set(a,'xlimmode','auto','ylimmode','auto');
    %S       = stim.stimulus(:,:,1);
    S       = permute(stim.stimulus(:,:,1),[2 1]);  % rotate by 90 for proper display
    [X Y]   = size(S);
    h = image(S,'parent',a);
    set(a,'xlim',[0 X+1],'ylim',[0 Y+1]);
    axis(a,'ij')
    set(h,'buttondownfcn',cb);
    drawLines(h);
    a = GetUIHandle(me,'clut');
    imagesc(stim.colmap,'parent',a);
    axis(a,'tight');
    box(a,'off');
    colormap(stim.colmap);  % replace me with user-selectable LUT?

function [] = drawLines(obj, bounds)
% Draws lines on the image to indicate which parameters will be analyzed
% If the second argument is omitted, lines will be drawn around the whole
% image.
a   = get(obj, 'Parent'); % parent axes
X   = get(obj, 'XData');
Y   = get(obj, 'YData');
if nargin == 1
    x     = X;
    y     = Y;
else
    U     = get(a,'XLim');
    V     = get(a,'YLim');
    pos   = get(a,'Position');
    start = bounds(1:2) - pos(1:2);     % the relative location of the lower right corner
    fin   = bounds(3:4);                % relative location of the lower right corner
    x(1)  = round(start(1) * U(2) / pos(3)) + U(1);
    x(2)  = round((start(1) + fin(1)) * U(2) / pos(3));
    y(2)  = Y(2) - round(start(2) * V(2) / pos(4)) + V(1) + 1;
    y(1)  = Y(2) - round((start(2) + fin(2)) * V(2) / pos(4)) + 1;
    if x(1) < X(1)
        x(1) = X(1)
    end
    if y(1) < Y(1)
        y(1) = Y(1);
    end
    if x(2) > Y(2)
        x(2) = Y(2);
    end
    if y(2) > Y(2)
        y(2) = Y(2);
    end

end
% clear existing lines
h   = findobj(a,'type','line');
delete(h);
line([x(1) x(1)], y, 'parent',a);
line([x(2) x(2)], y, 'parent',a);
line(x, [y(1) y(1)], 'parent',a);
line(x, [y(2) y(2)], 'parent',a);
str = sprintf('[%d %d; %d %d]',x(1), x(2), y(1), y(2));
SetUIParam(me,'analysiswindow','String',str);

function out = me()
out = mfilename;
