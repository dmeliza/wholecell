function [h1_est] = danlab_revcor(u,y,lags,Fs,options)

% DANLAB_REVCOR General Reverse Correlation Algorithm 
%
%  [h1_est] = danlab_revcor(u,y,lags,Fs,options)
%
%  INPUT
%    u    - stimulus matrix, 
%               2D - N-by-X Matrix (X Parameters in N Frame Stimulus)
%
%    y    - neural response, N-by-1 Vector
%
%    lags - temporal frame lags included in reverse correlation analysis (Default = 1)
%    Fs   - sampling rate of response
%
%    option 
%           - options.correct, ['yes' 'no'] correct for correlations in stimulus (Default = 'no')
%           - options.inverse, ['full' 'pseudo'] type of autocorrelation inverse (Default = 'full')
%           - options.fraction, [0 < fraction <= 1] fraction of eigenvectors to normalize by  (Default = 0.5)
%
%  OUTPUT
%    h1_est - estimated linear kernel,
%               2D - lags-by-X Matrix  
%
% Jon Touryan (06.30.03) $ Version 1.0 $

%%%%%%%%%%%% SETTINGS %%%%%%%%%%%
MEX_CODE = 1;       % Use Mex Code When Multipying Matrices (Uses Less Memory) [1 = yes, 0 = no]
PLOT_RESULT = 0;    % Plot Estimated Kernel [1 = yes, 0 = no]

%%% Check Input Arguments %%%
if nargin < 3
    % Set Default Lag Value %
    lags = 1;
end
if nargin < 4
    % Set Default Options %
    options = struct('correct','no');
end



%%%%%%%% CHECK INPUT %%%%%%%%
% Get Stimulus Dimensions %
[FRAMES X pages] = size(u);
DIMS = X * lags;

% Get Response Dimensions %
[rows cols] = size(y);

%%% Error Check %%%
% Check Stimulus - Response Match %
if (rows ~= FRAMES)
    error(' -> Number of frames in stimulus and response do not match!')
end
if (cols > 1)
    error(' -> Response must be a vector (single column)!')
end
if (pages > 1)
    error(' -> Stimulus must have only 2 dimensions!')
end



%%%%%%%% CONDITION INPUT %%%%%%%%
fprintf('Conditioning Input... \n')

% Make Zero Mean Stimulus %
u = u - mean(mean(u));

% Reshape 2D Stimulus %
% Stim = zeros(FRAMES,DIMS);
% lag_index = 0:(lags-1);
% for t = lags:FRAMES
%     time_step = u(t-lag_index,:);
%     Stim(t,:) = reshape(time_step,1,lags*X);
% end
Stim = StimulusMatrix(u,lags);



%%%%%%%% COMPUTE KERNEL %%%%%%%%
if ~isfield(options,'correct'); options.correct = 'no'; end;
switch options.display
case 'no'
    PLOT_RESULT = 0;
case 'yes'
    PLOT_RESULT = 1;
end
switch options.correct
    
    case 'no',
    
        %%% Compute Uncorrected Kernel %%%
        fprintf('Computing Kernel... \n')
        M = diag(var(Stim));
        h1_est = 1/(FRAMES-1) * inv(M) * (Stim' * y);
    

    case 'yes',
    
        %%% Compute Corrected Kernel %%%
        fprintf('Computing Autocorrelation Matrix... \n')
        if MEX_CODE
            M = matrix_corr(Stim);      % Mex Autocorrelation
        else
            M = Stim'*Stim;             % MATLAB Autocorrelation
        end
        
        if ~isfield(options,'inverse'); options.inverse = 'full'; end;
        switch options.inverse
            
            case 'full',
                
                % - Correct for Stimulus Bias via Full Autocorrelation Matrix Inverse - %
                fprintf('Computing Kernel... \n')
                %h1_est = inv(M) * Stim' * y;        % Via Matrix Inverse
                h1_est = M \ (Stim' * y);           % Via Cholesky Factorization (faster)
                
            case 'pseudo',
                
                % - Correct for Stimulus Bias via Pseudo Autocorrelation Matrix Inverse - %
                if ~isfield(options,'fraction'); options.fraction = 0.5; end;
                FRACTION = options.fraction;
                
                % Decompose Autocorrelation Matrix %
                [U S V] = svd(M);
                
                % Invert Autocorrelation Using A Reduced Eigenvector Set %
                S_inv_partial = zeros(DIMS);
                S_inv = inv(S);
                eig_limit = round(FRACTION * DIMS);                         % Eigenvalue Limit
                for i = 1:DIMS
                    if i <= eig_limit
                        S_inv_partial(i,i) = S_inv(i,i);                    % Keep These Values
                    else
                        S_inv_partial(i,i) = S_inv(eig_limit,eig_limit);    % Threshold These Values
                    end
                end
                M_pseudo = U * S_inv_partial * V';     % Partialy Inverted Autocorrelation Matrix
                fprintf('Computing Kernel... \n')
                h1_est = M_pseudo * Stim' * y;
                
            otherwise,
                
                error(' -> Invalid Option: options.inverse!')
        end
    
    otherwise,
        
        error(' -> Invalid Option: options.correct!')
    
end



%%%%%%%% CONDITION OUTPUT %%%%%%%%
h1_vec = h1_est;
h1_est = reshape(h1_est,lags,X);




if PLOT_RESULT
    
    %%%%%%%%% PLOT RESULTS %%%%%%%%
    disp('Plotting Result...')
    
    figure('Name','REVCOR Results');
    % Fiugre Parameters %
    set(gcf,...
        'Position',[100 300 500 250],...
        'Color',[1 1 1]); 
    clf;
    
    mx = max(max(abs(h1_est)));
    CLIM = [-mx mx];
    
    % Plot Linear Kernel %
    subplot(1,2,1)
    if (X > 1)
        % Image Plot %
        imagesc(h1_est,CLIM)
        %axis image
        set(gca,'XTick',[],'YTick',[])
        xlabel('Parameters')
        ylabel('Lags') 
        colormap(gray)
    else
        % Line Plot %
        t = 0:1000/Fs:1000*(length(h1_est)-1)/Fs;
        plot(t,h1_est,'-b','LineWidth',2)
        axis square
        set(gca,'YTick',[])
        xlabel('Time (ms)')
        %ylabel('Lags')
    end
    
    % Plot Response, Measured & Predicted %
    subplot(1,2,2)
    y_est = Stim * h1_vec;
    r = corrcoef(y_est,y);
    y_est = y_est * max(y)/max(y_est);
    t = 0:1000/Fs:1000*(length(y)-1)/Fs;
    plot(t,y,'-b')
    hold on
    plot(t,y_est,'-r')
    axis square
    if FRAMES > 100
        mx = max(abs(y));
        axis([0 1e5/Fs -mx mx])
    end
    set(gca,'YTick',[])
    xlabel('Time (ms)')
    ylabel('Response')
    title(['Corr Coef: ' num2str(r(1,2))])
    
end