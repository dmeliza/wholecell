function [] = PCA_2D(stim, resp, lags,option)
% This function performs a PCA/reverse correlation analysis of a stimulus/response pair.
% The stimulus is framshifted into a matrix with various lags and parameters,
% and the response is used to perform reverse correlation on the stimulus, or to
% weight the stimulus in preparation for PCA
%
% It makes a nice GUI, goes well with STRFGui
%
% Usage: [] = PCA_2D(stim, resp, lags,[option])
%
% stim   - the stimulus structure
% resp   - the response structure (r1 format).  
%          For multiple repeats, the analysis will be performed multiple times
%          and the results averaged together
% lags   - the window, in frames, to analyze.  Smaller windows save memory, etc.
% option - can be 'xcorr','pca',or 'both', to choose 1st and second order analyses
%          default is 'both'
% 
% See Also:
%           headers/stim_struct.m
%           headers/r1_struct.m
%           Analysis/PlotSTRF.m (used to view/analyze STRF)
%
% $Id$

% check arguments
error(nargchk(3,4,nargin))
if ~isfield(stim,'stimulus')
    error('Invalid stim structure.')
end
if ~isfield(resp,'data')
    error('Invalid response (r1) structure')
end
if nargin < 4
    option = 'both';
end

%%%%%%%% CHECK INPUT %%%%%%%%
% Get Stimulus Dimensions %
[I J K]          = size(stim.stimulus);
U                = (reshape(stim.stimulus,I*J,K))';  % reshape stimulus to N-by-X
[FRAMES X pages] = size(U);
DIMS             = X * lags;
REPEATS          = length(resp);

% Allocate output arrays
switch option
case 'xcorr'
    h1_est           = zeros([DIMS REPEATS]);         % time-parameter-by-repeat
case 'pca'
    h2_est           = zeros([DIMS DIMS REPEATS]);    % REPEAT eigenvector matrices
    h2_sig           = zeros([DIMS REPEATS]);    
case 'both'
    h1_est           = zeros([DIMS REPEATS]);         % time-parameter-by-repeat
    h2_est           = zeros([DIMS DIMS REPEATS]);    % REPEAT eigenvector matrices
    h2_sig           = zeros([DIMS REPEATS]);
end

for i = 1:REPEATS
    fprintf('Sweep %d:', i);
    bin     = fix(mean(diff(resp(i).timing)));      % frame rate of stimulus (in samples)
    y       = BinData(resp(i).data,bin,1);
    y       = y - mean(y);
    
    % Get Response Dimensions %
    [rows cols] = size(y);

    % Handle truncated or overlong responses
    if rows > FRAMES
        y    = y(1:FRAMES);              % response overrun
        rows = FRAMES;
        u   = U;        
    elseif rows < FRAMES
        u     = U(1:rows,:)              % truncated response
    else
        u   = U;
    end

    %%%%%%%% CONDITION INPUT %%%%%%%%
    fprintf('Conditioning Input... ')
    
    u = u - mean(mean(u));              % Make Zero Mean Stimulus %
    S = StimulusMatrix(u,lags);         % Reshape 2D Stimulus %

    if strcmpi(option,'both') | strcmpi(option,'xcorr')
        %%% Uncorrected 1st order Kernel %%%
        fprintf('1st order Kernel... ')
        M = diag(var(S));
        h1_est(:,i) = 1/(FRAMES-1) * inv(M) * (S' * y);
    end
    
    if strcmpi(option,'both') | strcmpi(option,'pca')
        %%% 2nd order kernel %%%
        fprintf('2nd order Kernel...')
        Sw = S .* repmat(y,1,size(S,2));    % weighted stimulus matrix
        C = Sw' * S;                        % covariance matrix    
        
        [h2_est(:,:,i) D U] = svd(C);              % compute eigenvectors
        h2_sig(:,i) = diag(D);                   % eigenvalues
    end
    fprintf('\n');
    clear('Sw','D','C','S','u')     % clear big arrays
end

% combine and reshape responses
pos = [1 1];
if strcmpi(option,'xcorr') | strcmpi(option,'both')
    h1_est  = mean(h1_est,2);
    k       = recondition(h1_est,[I J lags]);
    t       = 'h1';
    f       = plotstrf(struct('data',k,'title',t));
    movegui(f,'northwest')
    pos     = get(f,'position') - [0 370 0 0];
end
if strcmpi(option,'pca') | strcmpi(option,'both')
    h2_est  = mean(h2_est,3);
    h2_sig  = mean(h2_sig,2);
    k       = {recondition(h2_est(:,1),[I J lags]),...
               recondition(h2_est(:,2),[I J lags])};
    t       = {'h2(1)','h2(2)'};
    f       = ploteigs(h2_sig);
    movegui(f,[pos(1),pos(2)])
    pos     = get(f,'position') + [320 0 0 0];
    f       = plotstrf(struct('data',k,'title',t));
    movegui(f,[pos(1),pos(2)])
end
% plot


function k = recondition(in,dim)
% reshapes a (column) response vector into something more useful
k       = reshape(in,dim(3),dim(1)*dim(2));     % time by param
k       = reshape(k',dim);                      % X-Y-T

function f = ploteigs(eigenvalues)
% quick stem plot in a cute little window
f       = figure;
set(gcf,'color',[1 1 1],'position',[1 1 285 285],'menubar','none');
movegui(gcf,'northwest')
stem(eigenvalues)
set(gca,'XTick',[],'YTick',[])
xlabel('Rank')
ylabel('Eigenvalue')