function out = Parameterize(u, y, p)
%
% A general-purpose algorhythm that sorts and averages a matrix of
% response vectors along a single parameter.  It's useful in analyzing
% responses to sparse noise stimulation, where the values of the parameter
% are non-additive, making reverse correlation impossible.
%
%
%  out = Parameterize(u,y,[p])
%
%  INPUT
%    u    - stimulus parameter, N-by-1 vector
%
%    y    - frame-shifted response, N-by-M array
%
%    p    - lookup an individual parameter
%
%
%
%  OUTPUT
%    out  - I-by-J parameterized response matrix
%           I is the number of parameter values
%           J is equal to M (length of each frame)
%    out  - if argument p is supplied, a K-by-J response matrix
%           K are the number of times the parameter occurs
%           J is equal to M
%
%  $Id$

% check input arguments
error(nargchk(2,3,nargin))

% check input dimensions
[FRAMES PARAMS pages] = size(u);
[rows cols] = size(y);

if pages > 1 | PARAMS > 1
    error('Parameter must be a single column vector.');
elseif FRAMES ~= rows
    error('Stimulus length must be the same as the number of response frames.');
end

% Sort and average response matrix
params      = unique(u);                   % unique parameter values
if nargin < 3
    out  = zeros(length(params),cols);     % allocate output matrix
    for i = 1:length(params)
        j        = params(i);              % parameter value is an index
        ind      = find(u==j);             % which identifies frames assoc. with it
        out(i,:) = mean(y(ind,:),1);       % result is the mean of all frames assoc with param
    end
else
    % Look up individual parameter
    j   = params(p);
    ind = find(u==j);
    out = y(ind,:);
end