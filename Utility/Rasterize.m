function arr = Rasterize(vec)
%
% Rasterizes a vector into an array
%
% Usage: arr = Rasterize(vec)
%
% vec - an Nx1 or Nx2 array, in which the first column contains the value of a parameter
%       and the second column contains an optional secondary value
% arr - the output array, which will have dimensions of unique(N)xN
%
% $Id$

error(nargchk(1,1,nargin))

% I can't really think of a good way to do this except by looping through the vector
[N W] = size(vec);
if W == 1
    W        = 2;
    vec(:,2) = ones(N,1);
end
p     = unique(vec(:,1));
arr   = zeros(length(p),N);

for i = 1:N
    arr(vec(i,1),i) = vec(i,2);
end
