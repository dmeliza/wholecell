function h1_est = sparse_revcor(u, y, window, Fs_u, Fs_y)
% This function is analagous to danlab_revcor, only it's designed to work
% with data recorded from sparse noise stimuli.  The algorhythm is not
% strictly speaking reverse correlation.  Instead, the response is parsed into
% chunks following each stimulus frame.  Identical stimuli are grouped together
% and averaged, giving the impulse response function for each stimulus possibility.
%
% The total amplitude of the impulse function can be used to reconstitute the STRF, given
% the actual stimulus displayed for each location parameter.
%
%  [h1_est] = sparse_revcor(u,y,window,Fs_u, Fs_y)
%
%  INPUT
%    u    - stimulus matrix, N x 2 Array.  Column 1 is the location of the dot,
%           Column 2 is the color (0 or 1)
%
%    y    - neural response, N-by-1 Vector
%
%    window    - time (in 1/Fs units) to include in analysis 
%    Fs_y      - sampling rate of response
%    Fs_u      - sampling rate of the stimulus
%
%
%  OUTPUT
%    h1_est    - impulse functions for each location and value
%                I x 2 x J array (I parameters, 2 values, J samples)
%
%  $Id$

% OPTIONS
DISPLAY = 1;

% check input arguments
error(nargchk(5,5,nargin))

% check input dimensions
[FRAMES PARAMS pages] = size(u);
[len cols] = size(y);

if cols > 1
    error('Response must be a single column vector');
elseif pages > 1 | PARAMS ~= 2
    error('Stimulus dimensions must be Nx2x1');
end

% parse response into frame-shifted array
% this is not strictly necessary and may impose major memory constraints
% but it will make lookups against the response much faster
% A more sophisticated method would use the timing or sync data to align the chunks
% to the stimulus.
disp('Conditioning response...');
frate = floor(Fs_y / Fs_u); % samples per frame
rows = len / frate;  % number of chunks
cols = window * Fs_y; % length of each chunk
FRAMES = floor(len / frate - cols / frate);
R = zeros(FRAMES, cols);
u = u(1:FRAMES,:);
for i = 1:FRAMES
    ind = (i - 1) * frate;
    Y = y(ind+1:ind+cols)';
    R(i,:) = Y - mean(Y); % zero-mean response
end

% analyze stimulus
disp('Sorting response...');
mn = min(u(:,1)); % minimum parameter value
mx = max(u(:,1)); % maximum parameter value
mnmx = mn:mx;
h1_est = zeros(mx-mn+1,2,cols);
for i = 1:length(mnmx)
    j = mnmx(i);
    ind_on = find(u(:,1)==j & u(:,2)==1);
    ind_off = find(u(:,1)==j & u(:,2)==0);
    ON = R(ind_on,:);
    OFF = R(ind_off,:);
    h1_est(i,1,:) = mean(ON,1);
    h1_est(i,2,:) = mean(OFF,1);
end

% display results
if DISPLAY
    t = 0:1/Fs_y:window;
    figure
    set(gcf,'color',[1 1 1])
    
    subplot(1,2,1)
    OFF = squeeze(h1_est(:,1,:));
    [rows cols] = size(OFF);
    imagesc(t(1:cols),1:rows,OFF)
    colormap(gray)
    title('OFF')
    ylabel('Parameter')
    
    subplot(1,2,2)
    ON = squeeze(h1_est(:,2,:));
    imagesc(t(1:cols),1:rows,ON)
    colormap(gray)
    title('ON')
end