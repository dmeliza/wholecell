function a1 = SparseAnalysis(stim, resp, window, bin)
%
% This function is used to analyze the impulse response function of a system
% when sparse noise has been used as the stimulus.  Although S1Analysis will
% handle this just fine, often one wants to separate the ON and OFF components
% of the response function from each other. This function is a wrapper for
% S1Analysis() that will handle this.
%
% It makes a nice GUI.
%
% Usage: [h1_est, parameters] = SparseAnalysis(stim, resp, [window, [bin]])
%
% stim   - the stimulus structure (s1 or s0 structure)
% resp   - the response structure (r1 format)
% window - the window, in frames, to analyze.  Smaller windows save memory, etc.
%          default is 1
% bin    - the amount to bin the resulting response vectors, in samples.  If 0 or 1,
%          no binning will be done.  Default is 0
%
% a1    -  the results of the analysis, in an a1 structure array.  The kernel is an NxM
%          array describing the first M frames of the average response following
%          presentation of the stimulus defined by the Nth parameter. Contains the
%          optional .param and .strf fields.  The structure itself is an array, with
%          the first element representing the ON function and the second the OFF function.
%
% 
% See Also:
%           headers/s1_struct.m
%           headers/s0_struct.m
%           headers/r1_struct.m
%           headers/a1_struct.m
%           Analysis/Param2STRF.m (converts param array into STRF)
%           Analysis/PlotSTRF.m (used to view/analyze STRF)
%           Analysis/PlotParams.m (used to view/analyze parameter responses)
%
% 1.4:  major rewrite turns this into a module for STRFGui
% 1.10: rewritten into a wrapper for S1Analysis, now only accepts s1 inputs
%
% $Id$

error(nargchk(2,4,nargin))

if nargin < 3
    window = 1;
end
if nargin < 4
    bin = 0;
end

if ~isfield(stim,'type')
    error('Stimulus structure is malformed.');
end
S   = warning('off');
switch lower(stim.type)
case 's0'
    stim.param = stim.parameters;
    a1         = S1Analysis(stim,resp,window,bin);
    [p ind]    = unique(stim.parameters,'rows');       % recalc the uniques
    uv         = stim.stimulus(:,:,ind);               % pull out unit vectors
    ind_on     = find(p(:,end));                       % ON parameter indices
    ind_off    = find(p(:,end)==0);                    % OFF parameter indices
    sz         = size(p,1);
case 's1'
    a1         = S1Analysis(stim,resp,window,bin);
    ind_on     = find(a1.param > 0);
    ind_off    = find(a1.param < 0);
    % generate unit vectors
    fp  = stim.static;                                      % function parameters
    sz  = length(a1.param);                                 % size of basis set
    uv  = zeros(stim.x_res,stim.y_res,sz);                  % pre-allocate
    for i = 1:sz
        uv(:,:,i) = feval(stim.mfile, fp{:}, a1.param(i,:));      % generate unit vector
    end
end
warning(S);
% Compute ON and OFF functions
uv      = reshape(uv, prod([stim.x_res,stim.y_res]),sz);
uv      = uv - mean(mean(uv));                  % zero mean stimulus
k_on    = a1.kern(ind_on,:);
k_off   = a1.kern(ind_off,:);
ON      = uv(:,ind_on) * k_on;
ON      = reshape(ON,stim.x_res,stim.y_res,size(k_on,2));
OFF     = uv(:,ind_off) * k_off;
OFF     = -reshape(OFF,stim.x_res,stim.y_res,size(k_off,2));
% repackage into a1 if nargout > 0
if nargout > 0
    a1          = repmat(a1,2,1);
    a1(1).strf  = ON;
    a1(1).kern  = k_on;
    a1(1).param = a1(1).param(ind_on,:);
    a1(2).strf  = OFF;
    a1(2).kern  = k_off;
    a1(2).param = a1(2).param(ind_off,:);
else
    % plot things
    PlotParams(struct('data',{k_on,k_off},...
        'title',{'ON','OFF'},...
        'frate',{a1.frate a1.frate}));
    movegui(gcf,'northwest');
    
    pos      = get(gcf,'Position');
    PlotSTRF(struct('data',{ON,OFF},'title',{'ON','OFF'},'frate',{a1.frate,a1.frate}));
    movegui(gcf,[pos(1) pos(2)-340])
end
