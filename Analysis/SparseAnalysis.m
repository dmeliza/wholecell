function [h1_est, parameters] = SparseAnalysis(stim, resp, window, bin)
% This function performs a sparse-noise analysis of a stimulus/response pair.
% The response is frame-shifted into a matrix with a width equal to the analysis
% window, and the stimulus (which must contain the .parameters field) is used
% to combine and average the responses to each parameter.
%
% It makes a nice GUI.
%
% Usage: [h1_est, parameters] = SparseAnalysis(stim, resp, [window, [bin]])
%
% stim   - the stimulus structure
% resp   - the response structure (r1 format)
% window - the window, in frames, to analyze.  Smaller windows save memory, etc.
%          default is 1
% bin    - the amount to bin the resulting response vectors, in samples.  If 0 or 1,
%          no binning will be done.  Default is 0
%
% h1_est    -  an NxM array describing the first M samples following the presentation of
%              a stimulus parameter (whose value can range from 1 to N). Repeats are
%              during the frameshift stage, and the individual "responses" to each
%              parameter are preserved.
% parameters - what each parameter value in h1_est represents (in terms of the original
%              parameter array
% 
% See Also:
%           headers/stim_struct.m
%           headers/r1_struct.m
%           Analysis/Param2STRF (converts param array into STRF)
%           Visual/ViewSTRF.m (used to view/analyze STRF)
%
% 1.4: major rewrite turns this into a module for STRFGui
%
% $Id$

error(nargchk(2,4,nargin))

if nargin < 3
    window = 1;
end
if nargin < 4
    bin = 0;
end

%initFigure;
analyze(stim, resp, window, bin);

function [] = initFigure()
% Initializes the figure
f   = figure;
movegui(f,'northwest');
set(f,'Color',[1 1 1],'Name','Sparse Analysis','NumberTitle','off');
%'Position',[360 314 560 520]

function [] = analyze(stim, resp, window, bin)
% stimulus-param mappings and the parameter vector
[stimulus param params] = unique(stim.parameters,'rows'); % all the unique combinations of values
stimulus = binarystimulus(stimulus);                   % make z values 0 and 1
ind_on   = find(stimulus(:,end));                         % ON parameters
ind_off  = find(stimulus(:,end)==0);                      % OFF parameters

% allocate output array
repeats  = length(resp);
h1_est   = zeros(length(param), window);
R        = [];
P        = [];

% loop through each of the sweeps
S = warning('off');                                     % frameshift can throw warnings
for i = 1:repeats
    fprintf('Sweep %d: ', i);
    r       = double(resp(i).data);
    timing  = resp(i).timing;

    % frame shift response
    fprintf('Conditioning response... \n');
    r    = FrameShift(r,timing,window,'correct');         % frame shift data
    len  = size(r,1);                                      % number of parameters we can look at
    R    = cat(1,R,r);                                     % response matrix
    P    = cat(1,P,params(1:len));                         % parameter vector
end
warning(S);

% parameterize response
fprintf('Parameterizing response...\n');
h1_est        = Parameterize(P,R);          % combine and average
% bin the result if neccessary
if bin > 1
    h1_est    = BinData(h1_est,bin,2);
    R         = BinData(R,bin,2);
end
cb       = @clickme;
frate    = getpref('strfGUI','srate');
PlotParams(struct('data',{h1_est(ind_on,:),h1_est(ind_off,:)},...
                  'title',{'ON','OFF'},...
                  'frate',{frate frate},...
                  'cb',{{cb,R,P,ind_on},{cb,R,P,ind_off}}));
movegui(gcf,'northwest');              

% generate STRF and plot it
fprintf('Computing STRF...\n');
stimulus = stim.stimulus(:,:,param);                     % 2D arrays for each stimulus
stimulus = permute(stimulus,[3 1 2]);                    % reshape for use with STRF
ON       = Param2STRF(h1_est(ind_on, :), stimulus(ind_on, :,:));
OFF      = Param2STRF(h1_est(ind_off,:), stimulus(ind_off,:,:));
frate    = getpref('strfGUI','srate');
pos      = get(gcf,'Position');
PlotSTRF(struct('data',{ON,OFF},'title',{'ON','OFF'},'frate',{frate,frate}));
movegui(gcf,[pos(1) pos(2)-340])

function [] = clickme(obj, event, R, P, ind)
% handles double clicks on sparse analysis window
type    = get(gcf,'selectiontype');
if strcmpi(type,'open');
    % locate the click
    a       = get(obj,'Parent');
    Y       = get(a,'CurrentPoint');
    y       = round(Y(1,2));
    lim     = get(obj,'XData');
    % draw a line
    h       = findobj(gcf,'type','line');
    delete(h);
    line([lim(1) lim(end)],[y y]);
    % look up the parameter
    param   = ind(y);
    resp    = Parameterize(P,R,param);
    figure
    movegui(gcf,'southeast');
    str     = ['Parameter ' num2str(param)];
    set(gcf,'color',[1 1 1],'name',str,'NumberTitle','off');
    mtrialplot(lim,resp');
    xlabel('Time (s)')
    title(str);
    %plot(s.k(y,:));
end

function [X, Y] = getIndices(s)
% converts a size vector into two indexing vectors
% uses the strfGUI.srate vector to set the time vector (dimension 2)
srate   = getpref('strfGUI','srate');
Y       = 1:s(1);
X       = 0:1/srate:(s(2)-1)/srate;
    
function stim = binarystimulus(stim)
% fixes the z values in the Nx3 array to be 1 and 0
mx = max(stim(:,end));
mn = min(stim(:,end));
stim(:,end) = (stim(:,end) - mn) / (mx - mn);