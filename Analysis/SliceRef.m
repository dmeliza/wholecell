function out = SliceRef(A, dim, slice)
%
% A more generalized way to retrieve a slice or slices from a multi-dimensional
% array. Useful when the number of dimensions in the array are variable.
% 
% If A is a 4-D array:
% SliceRef(A, 3, 1:3) == A(:,:,1:3,:);
% SliceRef(A, 4, 10) == A(:,:,:,10);
%
% Usage: out = SliceRef(array, dim, slice)
%
%   array   - the array to be sliced
%   dim     - the dimension on which to take the slice
%   slice   - a vector or scalar defining which slices to take
%
%   out     - the slice or slices
%
% $Id$
error(nargchk(3,3,nargin))
dims = ndims(A);

% construct reference string
s = '';
for i = 1:dims
    if i == dim
        ins = 'slice';
    else
        ins = ':';
    end
    s = sprintf('%s%s,',s,ins);
end
s = s(1:end-1); % remove trailing comma
sf = sprintf('A(%s)',s);

out = eval(sf);