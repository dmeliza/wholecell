function h1_est = S1Analysis(stim, resp, window, bin)
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
% Usage: h1_est = S1Analysis(s1, r1, [window, [bin]])
%
% s1     - the s1 stimulus structure
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
% 
% See Also:
%           headers/s1_struct.m
%           headers/r1_struct.m
%           Analysis/Param2STRF (converts param array into STRF)
%           Analysis/PlotSTRF.m (used to view/analyze STRF)
%           Analysis/PlotParams.m (used to view/analyze parameter responses)
%
%
% $Id$

error(nargchk(2,4,nargin))

if nargin < 3
    window = 1;
end
if nargin < 4
    bin = 0;
end

% find all the unique parameter combinations
[stimulus param params] = unique(stim.param,'rows'); % all the unique combinations of values

% initialize output arrays
repeats  = length(resp);
R        = [];
P        = [];
%clear('stim');                                   % clear up some memory

% loop through each of the sweeps
S = warning('off');                                     % frameshift can throw warnings
for i = 1:repeats
    fprintf('Sweep %d: ', i);

    % frame shift response
    fprintf('Conditioning response... \n');
    r     = FrameShift(double(resp(i).data),...
                      resp(i).timing,...
                      window,'correct');               % frame shift data
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
h1_est   = Parameterize(P,R);          % combine and average
cb       = @clickme;
frate    = getpref('strfGUI','srate');
PlotParams(struct('data',h1_est,...
                  'title','Parameters',...
                  'frate',frate,...
                  'cb',{{cb,R,P}}));
movegui(gcf,'northwest');              

% Now we have to convert the parameterized responses into a "real" STRF.  The most
% general way to do this is to use the mfile specification in the s1 structure to
% generate the unit vectors for the basis set, then scale these vectors by
% the values of the parameterized strf.  Of course, there are more elegant ways
% to transform particular basis sets, but this should be about as unbiased as we can get.
fprintf('Computing STRF...\n');
mf = stim.mfile;
[path func] = fileparts(mf);
if ~exist(func)
    errordlg(['Cannot find ' func ': no STRF generated']');
    return
end
fp  = stim.static;                                      % function parameters
sz  = length(param);                                    % size of basis set
uv  = zeros(stim.x_res,stim.y_res,sz);                  % pre-allocate
for i = 1:sz
    uv(:,:,i) = feval(func, fp{:}, stimulus(i,:));      % generate unit vector
end
uv   = reshape(uv, prod([stim.x_res,stim.y_res]),sz);   % reshape to pixel X param
strf = uv * h1_est;                                     % matrix multiply to eliminate param
strf = reshape(strf,stim.x_res,stim.y_res,size(h1_est,2));
PlotSTRF(struct('data',strf,'title','STRF','frate',frate));
pos      = get(gcf,'Position');
movegui(gcf,[pos(1) pos(2)-340])

% 
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
    %plot(s.k(y,:));
end
