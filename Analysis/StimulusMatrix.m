function S = StimulusMatrix(stim, lags)
%
% Conditions an N-by-X Matrix (X Parameters in N Frame Stimulus) into
% a stimlulus matrix that can be used for 1st and 2nd order analysis
% for receptive fields
%
% Usage: S = StimulusMatrix(stimulus, lags)
%
% stimulus - N-by-X Matrix (X Parameters in N Frame Stimulus)
% lags     - scalar, number of lags to analyze
%
% $Id$

error(nargchk(2,2,nargin))

[FRAMES X pages] = size(stim);
DIMS = X * lags;
S = zeros(FRAMES,DIMS);
lag_index = 0:(lags-1);
for t = lags:FRAMES
    time_step = stim(t-lag_index,:);
    S(t,:) = reshape(time_step,1,lags*X);
end