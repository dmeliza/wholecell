function a1 = S1Analysis(stim, resp, window, bin)
% This function performs a sparse-noise analysis of a stimulus/response pair.
% It's the next generation from SparseAnalysis(), in that it uses the parametric
% s1 stimulus structure. Sparse noise analysis works by computing the mean responses
% to a set of random variables S.  These variables usually exist in some kind of
% parametric space (e.g. square location in classical sparse noise) or shifted
% basis set (e.g. fourier space for ringach/shapley grating noise).  This is fundamentally
% different from reverse correlation in that we are analyzing the stimulus-conditional response
% distributions rather than response-conditional stimulus distributions.
%
% In this function, this operation is implemented as follows:
% The response is frame-shifted into a matrix with a width equal to the analysis
% window, and then sorted by location in parameter space.  If there are multiple
% responses to a parameter set, these are averaged.
%
%
% Usage: a1 = S1Analysis(s1, r1, [window, [bin]])
%
% s1     - the s1 stimulus structure
% resp   - the response structure (r1 format)
% window - the window, in frames, to analyze.  Smaller windows save memory, etc.
%          default is 1
% bin    - the amount to bin the resulting response vectors, in samples.  If 0 or 1,
%          no binning will be done.  Default is 0
%
% a1    -  the results of the analysis, in an a1 structure.  The kernel is an NxM
%          array describing the first M frames of the average response following
%          presentation of the stimulus defined by the Nth parameter. Contains the
%          optional .param and .strf fields.
% 
% See Also:
%           headers/s1_struct.m
%           headers/r1_struct.m
%           headers/a1_struct.m
%           Analysis/FrameShift.m (creates a frame-shifted response array - similar to buffer())
%           Analysis/Parameterize.m (sorts response array by stimulus parameters)
%           Analysis/Param2STRF (converts param array into STRF)
%           Analysis/PlotSTRF.m (used to view/analyze STRF)
%           Analysis/PlotParams.m (used to view/analyze parameter responses)
%
%
% $Id$

MODE = 'correctprev';      % determines the correction mode used to combine responses

error(nargchk(2,4,nargin))

if nargin < 3
    window = 1;
end
if nargin < 4
    bin = 0;
end

% find all the unique parameter combinations
[stimulus param params] = unique(stim.param,'rows'); % all the unique combinations of values
a1.param = stimulus;

% initialize output arrays
repeats  = length(resp);
R        = [];
P        = [];

% loop through each of the sweeps
S = warning('off');                                     % frameshift can throw warnings
for i = 1:repeats
    fprintf('Sweep %d: ', i);

    % frame shift response
    fprintf('Frameshifting response... \n');
    r     = FrameShift(double(resp(i).data),...
                      resp(i).timing,...
                      window,MODE);               % frame shift data
    len   = size(r,1);                                      % number of parameters we can look at
    
    if bin > 1
        r = BinData(r,bin,2);                               % binning data now saves a lot of memory
    end
    R     = cat(1,R,r);                                     % response matrix
    P     = cat(1,P,params(1:len));                         % parameter vector
end
warning(S);                                

% parameterize response
fprintf('Parameterizing response...\n');
[a1.kern, a1.vkern]      = Parameterize(P,R);          % combine and average
a1.frate               = getpref('strfGUI','srate');
if nargout == 0                        % no display if output values are assigned
    cb       = @clickme;
    PlotParams(struct('data',a1.kern,...
        'title','Parameters',...
        'frate',a1.frate,...
        'cb',{{cb,R,P}}));
    movegui(gcf,'northwest');
end


% check if we can convert to STRF
err = 0;
if isfield(stim,'mfile')
    [path func] = fileparts(stim.mfile);
    if ~exist(func)
        err = 1;
    end
else
    err = 1;
end
if err
    warning('Unable to load conversion function.  No STRF computed.');
    return
end

% Now we have to convert the parameterized responses into a "real" STRF.  The most
% general way to do this is to use the mfile specification in the s1 structure to
% generate the unit vectors for the basis set, then scale these vectors by
% the values of the parameterized strf.  Of course, there are more elegant ways
% to transform particular basis sets, but this should be about as unbiased as we can get.
fprintf('Computing STRF...\n');
fp  = stim.static;                                      % function parameters
sz  = length(param);                                    % size of basis set
Z   = feval(func, fp{:}, stimulus(1,:));                % generate the first frame
[x y] = size(Z);
uv  = zeros([x y sz]);                  % pre-allocate
for i = 1:sz
    uv(:,:,i) = feval(func, fp{:}, stimulus(i,:));      % generate unit vector
end
uv    = reshape(uv, prod([x,y]),sz);   % reshape to pixel X param
strf  = uv * a1.kern;                                    % matrix multiply to eliminate param
vstrf = uv * a1.vkern;                                   % variance strf
a1.strf  = reshape(strf,x,y,size(a1.kern,2));
a1.vstrf = reshape(vstrf,x,y,size(a1.kern,2));

% display only if output values are unassigned
if nargout == 0                                         
    PlotSTRF(struct('data',a1.strf,'title','STRF','frate',a1.frate));
    pos      = get(gcf,'Position');
    movegui(gcf,[pos(1) pos(2)-340])
end
 
function [] = clickme(obj, event, R, P)
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
    resp    = Parameterize(P,R,y);
    figure
    movegui(gcf,'southeast');
    str     = ['Parameter ' num2str(y)];
    set(gcf,'color',[1 1 1],'name',str,'NumberTitle','off');
    mtrialplot(lim,resp');
    xlabel('Time (s)')
    title(str);
end
