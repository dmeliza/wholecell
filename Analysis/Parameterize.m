function out = Parameterize(u, y)
%
% A general-purpose algorhythm that sorts and averages a matrix of
% response vectors along a single parameter.  It's useful in analyzing
% responses to sparse noise stimulation, where the values of the parameter
% are non-additive, making reverse correlation impossible.
%
%
%  out = Parameterize(u,y)
%
%  INPUT
%    u    - stimulus parameter, N-by-1 vector
%
%    y    - frame-shifted response, N-by-M array
%
%
%
%  OUTPUT
%    out  - I-by-J parameterized response matrix
%           I is the number of parameter values
%           J is equal to M (length of each frame)
%
%  $Id$

% check input arguments
error(nargchk(2,2,nargin))

% check input dimensions
[FRAMES PARAMS pages] = size(u);
[rows cols] = size(y);

if pages > 1 | PARAMS > 1
    error('Parameter must be a single column vector.');
elseif FRAMES ~= rows
    error('Stimulus length must be the same as the number of response frames.');
end

% Sort and average response matrix
params = unique(u); % unique parameter values
out  = zeros(length(params),cols);
for i = 1:length(params)
    j = params(i);
    ind = find(u==j);
    out(i,:) = mean(y(ind,:),1);
end