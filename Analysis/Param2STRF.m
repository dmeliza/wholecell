function [strf] = Param2STRF(responses, parameters)
%
% Converts an NxM array of impulse responses into an IxJxM arrays
% which are the spatial-temporal receptive fields (ON and OFF respectively)
% The "real" stimuli that are generated are the same as a sparse noise frame
%
% Usage: [strf_on strf_off] = Param2STRF(responses, parameters)
%
%
% responses        - NxM array. N parameters, M time points
% parameters       - NxIxJ array. N parameters, IxJ stimulus
%                    to map from parameter values to real stimuli
%
% strf             - IxJxM spatiotemporal receptive field
%
% $Id$

error(nargchk(2,2,nargin))

[PARAMS SAMPLES] = size(responses);
[N I J] = size(parameters);

if PARAMS ~= N
    error('Number of parameters must be the same in response and parameter arrays');
end

% condition parameters to zero mean
m = mean(mean(mean(parameters)));
parameters = parameters - repmat(m,size(parameters));

% allocate output
strf = zeros(I,J,SAMPLES);

% loop through timeframes and assign values to each parameter
for i=1:SAMPLES
    R           = responses(:,i);            % response to each parameter at time i
    R           = repmat(R,[1,I,J]);         % response mapped to each pixel
    strf(:,:,i) = mean((R .* parameters),1); % response * parameter value at each pixel
end