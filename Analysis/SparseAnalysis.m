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


% % stimulus-param mappings and the parameter vector
% [stimulus param params] = unique(stim.parameters,'rows'); % all the unique combinations of values
% parameters = stim.stimulus(:,:,param);                     % 2D arrays for each stimulus
% stimulus   = binarystimulus(stimulus);                     % make z values 0 and 1
% ind_on     = find(stimulus(:,end));                         % ON parameters
% ind_off    = find(stimulus(:,end)==0);                      % OFF parameters
% 
% % initialize output arrays
% repeats  = length(resp);
% R        = [];
% P        = [];
% clear('stim');                                   % clear up some memory
% 
% % loop through each of the sweeps
% S = warning('off');                                     % frameshift can throw warnings
% for i = 1:repeats
%     fprintf('Sweep %d: ', i);
% 
%     % frame shift response
%     fprintf('Conditioning response... \n');
%     r     = FrameShift(double(resp(i).data),...
%                       resp(i).timing,...
%                       window,'correctprev');                   % frame shift data
%     len   = size(r,1);                                      % number of parameters we can look at
%     
%     if bin > 1
%         r = BinData(r,bin,2);                               % binning data now saves a lot of memory
%     end
%     R     = cat(1,R,r);                                     % response matrix
%     P     = cat(1,P,params(1:len));                         % parameter vector
% end
% warning(S);
% 
% % parameterize response
% fprintf('Parameterizing response...\n');
% h1_est        = Parameterize(P,R);          % combine and average
% % bin the result if neccessary
% % if bin > 1
% %     h1_est    = BinData(h1_est,bin,2);
% %     R         = BinData(R,bin,2);
% % end
% cb       = @clickme;
% frate    = getpref('strfGUI','srate');
% PlotParams(struct('data',{h1_est(ind_on,:),h1_est(ind_off,:)},...
%                   'title',{'ON','OFF'},...
%                   'frate',{frate frate},...
%                   'cb',{{cb,R,P,ind_on},{cb,R,P,ind_off}}));
% movegui(gcf,'northwest');              
% 
% % generate STRF and plot it
% fprintf('Computing STRF...\n');
% P        = permute(parameters,[3 1 2]);                    % reshape for use with STRF
% ON       = Param2STRF(h1_est(ind_on, :), P(ind_on, :,:));
% OFF      = Param2STRF(h1_est(ind_off,:), -P(ind_off,:,:)); % invert off parameters
% frate    = getpref('strfGUI','srate');
% pos      = get(gcf,'Position');
% PlotSTRF(struct('data',{ON,OFF},'title',{'ON','OFF'},'frate',{frate,frate}));
% movegui(gcf,[pos(1) pos(2)-340])
% 
% function [] = clickme(obj, event, R, P, ind)
% % handles double clicks on sparse analysis window
% type    = get(gcf,'selectiontype');
% if strcmpi(type,'open');
%     % locate the click
%     a       = get(obj,'Parent');
%     Y       = get(a,'CurrentPoint');
%     y       = round(Y(1,2));
%     lim     = get(obj,'XData');
%     % draw a line
%     h       = findobj(gcf,'type','line');
%     delete(h);
%     line([lim(1) lim(end)],[y y]);
%     % look up the parameter
%     param   = ind(y);
%     resp    = Parameterize(P,R,param);
%     figure
%     movegui(gcf,'southeast');
%     str     = ['Parameter ' num2str(param)];
%     set(gcf,'color',[1 1 1],'name',str,'NumberTitle','off');
%     mtrialplot(lim,resp');
%     xlabel('Time (s)')
%     title(str);
%     %plot(s.k(y,:));
% end
% 
% function [X, Y] = getIndices(s)
% % converts a size vector into two indexing vectors
% % uses the strfGUI.srate vector to set the time vector (dimension 2)
% srate   = getpref('strfGUI','srate');
% Y       = 1:s(1);
% X       = 0:1/srate:(s(2)-1)/srate;
%     
% function stim = binarystimulus(stim)
% % fixes the z values in the Nx3 array to be 1 and 0
% mx = max(stim(:,end));
% mn = min(stim(:,end));
% stim(:,end) = (stim(:,end) - mn) / (mx - mn);