function [strf_on, strf_off] = Param2STRF(responses, parameters, on, off)
%
% Converts an NxM array of impulse responses into two IxJxM arrays
% which are the spatial-temporal receptive fields (ON and OFF respectively)
% The "real" stimuli that are generated are the same as a sparse noise frame
%
% Usage: [strf_on strf_off] = Param2STRF(responses, parameters)
%
%
% responses        - NxM array. N parameters, M time points
% parameters       - NxIxJ array. N parameters, IxJ stimulus
%                    to map from parameter values to real stimuli
% on               - indices of "ON" stimuli
% off              - indices of "OFF" stimuli
%
% $Id$

error(nargchk(4,4,nargin))

[PARAMS SAMPLES] = size(responses);
[N I J] = size(parameters);

if PARAMS ~= N
    error('Number of parameters must be the same in response and parameter arrays');
elseif length(on) + length(off) ~= PARAMS
    error('ON and OFF vectors must add up to the number of parameters');
end

% condition parameters to zero mean
m = mean(mean(mean(parameters)));
parameters = parameters - repmat(m,size(parameters));

strf_on = zeros(I,J,SAMPLES);
strf_off = zeros(I,J,SAMPLES);
ON = parameters(on,:,:);
OFF = parameters(off,:,:);

for i=1:SAMPLES
    R = responses(:,i); % response to each parameter at time i
    R_ON = repmat(R(on),[1,I,J]);
    R_OFF = repmat(R(off),[1,I,J]);
    strf_on(:,:,i) = mean((R_ON .* ON),1);
    strf_off(:,:,i) = mean((R_OFF .* OFF),1);
end