function [h1_est, h2_est, h2_sig] = revcor12(u, y, lags, Fs)
% Computes the first- and second-order kernels from intracellular data
% by constructing a covariance matrix and using singular
% value decomposition.  No correction is made for correlations within the stimulus,
% so if Fs is greater than the frame rate of the stimulus, the
% result will be convolved by the autocorrelation of the stimulus.
%
% [h1_est, h2_est, h2_sig] = second_order(stim, resp, lags, Fs)
% stim - the stimulus vector (N by 1 vector)
%        no correction is made for correlations within the stimulus
% resp - the response vector (N by 1 vector) 
%        (must be downsampled to frame rate of stimulus)
% lags - the number of frames to include in the analysis
% Fs   - the frame rate of the stimulus/response
%
% h1_est - a row vector comprising the first order kernel
% h2_est - a row matrix of eigenvectors (e.g. h2_est(:,1) is first eigenvector)
% h2_sig - the eigenvalues (arranged by rank)
%
% For all internal analyses, k2 is composed of the first two eigenvectors
% in h2_est. They may not both be relevant.
%
% Dan Meliza & Jon Touryan $Id$

%%%%%%%%%%%%%%%%%
% Settings
DISPLAY = 1;        % Display results
ORTHO = 0;          % Orthogonalize k1

% check arguments
error(nargchk(4,4,nargin));

% check input dimensions
[frames params] = size(u);
[rows cols] = size(y);
if frames ~= rows
    error('Stimulus and response must be equal length');
elseif cols > 1
    error('Response must be a column vector (N x 1)');
elseif params > 1
    error('Only single parameter inputs accepted.');
end

%%%%%%%% CONDITION INPUT %%%%%%%%
fprintf('Conditioning Input... \n')

% Make Zero Mean Stimulus %
u = u - mean(mean(u));

% Reshape 2D Stimulus into [Frames by Lags] matrix
S = zeros(frames, lags);
lag_index = 0:(lags-1);
for t = lags:frames
    time_step = u(t-lag_index,:);
    S(t,:) = reshape(time_step,1,lags);
end

%%%%%%%% COMPUTE KERNEL 1 %%%%%%%%
% The first order kernel is computed from the cross-correlation
% of the stimulus with the response. This is equivalent to
% multiplying the transposed stimulus matrix by the response vector
fprintf('Computing 1st order kernel...\n');
M = diag(var(S));
h1_est = 1/(frames-1) * inv(M) * (S' * y);

%%%%%%%% COMPUTE KERNEL 2 %%%%%%%%
fprintf('Computing 2nd order kernel... \n')
% Calculate weighted stimulus matrix: the rows of the
% stimulus matrix multiplied by Vm (or Iclamp)
%z = (S * h1_est) ./ y;
Sw = S .* repmat(y,1,lags);
% the covariance matrix is Sw'*S
% Matlab matrix multiplication is fast but uses a lot of memory
C = Sw'*S; 
% Singular value decomposition of covariance matrix (insert handwaving)
[h2_est D U] = svd(C);
h2_sig = diag(D);

%%%%%%%% Orthogonalize kernels ************
if ORTHO
    fprintf('Orthogonalizing kernels... \n');
    h2_est = h2_est(:,1:2);
    h1_est = orthogonalize(h1_est, h2_est);
end


if DISPLAY
    %%%%%%%%% PLOT RESULTS %%%%%%%%
    disp('Plotting Result...')
    
    figure('Name','REVCOR Results');
    % Fiugre Parameters %
    set(gcf,...
        'Position',[100 300 500 500],...
        'Color',[1 1 1]); 
    clf;

    % Plot kernels (k1 and k2(1:2))
    subplot(2,2,1)
    t = 0:1000/Fs:1000*(length(h1_est)-1)/Fs;
    plot(t,rescale(h1_est),'-k','LineWidth',2)
    hold on
    plot(t,rescale(h2_est(:,1)),'-b','LineWidth',1)
    plot(t,rescale(h2_est(:,2)),'-r','LineWidth',1)
    hold off
    legend('k1','k2(1)','k2(2)');
    axis square
    set(gca,'YTick',[])
    xlabel('Time (ms)')
    title('Temporal kernels');
    
    % Plot eigenvalues
    subplot(2,2,2)
    stem(diag(D));
    set(gca,'XTick',[],'YTick',[])
    axis square
    xlabel('Rank')
    ylabel('Eigenvalue');

    % Plot Response, Measured & Predicted
    % For linear kernel
    subplot(2,2,3)
    y_est = S * h1_est;  % convolve stimulus with linear kernel (= projection)
    y_est = y_est(lags+1:end); % clip off zero values
    z = y(lags+1:end);
    r = corrcoef(y_est,z); % correlation of projection with response
    y_est = y_est * max(z)/max(y_est); % normalize response
    t = 0:1000/Fs:1000*(length(y_est)-1)/Fs; % generate a time vector for plotting
    plot(t,z,'-b')
    hold on
    plot(t,y_est,'-k')
    axis square
    axis tight
    if frames > 100
        mx = max(abs(z));
        axis([0 1e5/Fs -mx mx])
    end
    set(gca,'YTick',[])
    xlabel('Time (ms)')
    ylabel('Response')
    title(['Corr Coef (k1): ' num2str(r(1,2))])    

    % Plot projection-response histograms to assess nonlinearity
    subplot(2,2,4)
    vecs = 2;
    lines = {'-b','-r'};
    [x,p] = ProjectionResponse(z,y_est);
    plot(x,p,'-k','Linewidth',2);
    hold on
    for i = 1:vecs
        y_est = S * h2_est(:,i); % estimated response for eigenvector i
        [x,p] = ProjectionResponse(z,y_est(lags+1:end));
        plot(x,p,lines{i},'Linewidth',2);
    end
    plot(x,zeros(size(x)),':k');
    axis tight
    axis square
    set(gca,'YTick',[],'XTick',[])
    xlabel('Projection')
    ylabel('Response')
    title('Response Projection');
    hold off
    
end

function v3 = orthogonalize(u1,v)
% dirty non-general orthogonalize a 3rd vector against two
% already othro vectors
% u1 - Nx1 non-orthogonal vector
% v - Nx2 orthogonal vectors
v1 = v(:,1);
v2 = v(:,2);
v3 = u1 - dot(u1,v1)/dot(v1,v1)*v1 - dot(u1,v2)/dot(v2,v2)*v2;

function y = rescale(y)
% normalizes vector to a power of 1
% (divide by sqrt of dot product)
y = y - mean(y);
y = y / sqrt(dot(y,y));