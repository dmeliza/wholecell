function data = BinData(data, binfactor, dimension)
% Generalized data binning function.  The default is to bin along dimension 2,
% which given Matrix A:
% [1 2 3 4]
% [2 3 4 5]
% [5 6 7 8]
% then BinData(A,2) gives
% [1.5 3.5]
% [2.5 4.5]
% [5.5 7.5]
% while BinData(A,2,1) would give
% [1.4 2.5 3.5 4.5]
% [ 5   6   7   8 ]
%
%
% 1.3 - now attempts to detect if the input is a column
% 1.4 - generalized to any number of dimensions, modulus is preserved
%
% $Id$

error(nargchk(2,3,nargin))

if nargin < 3
    dimension = 2;
end

ndim = ndims(data);
dims = size(data);

if dimension > ndim
    error(['Input matrix has only ' num2str(ndim) ' dimensions!']);
end

% catch column vectors, which don't bin properly with the default dimension
if ndim == 2 & dims(2) == 1
    dimension = 1;
end

% we have to permute the dimensions of the input array so that the values will
% be read in correctly by reshape
neworder = [dimension setdiff(1:ndim,dimension)];
data     = permute(data, neworder);
dims     = dims(neworder);

% compute the shape of the final matrix & extract the modulus
row  = floor(dims(1) / binfactor);         % number of hyperrows in the binned dimension
last = dims(1) - mod(dims(1),binfactor);   % the index of the last evenly divisible hyperrow
if last < dims(1)
    nd   = SliceRef(data,1,1:last);               % the reshapable portion of the matrix
    mod  = SliceRef(data,1,last+1:dims(1));       % the modulus
else
    nd   = data;
    mod  = [];
end

% bin the data by reshaping and averaging the matrix
nd              = reshape(nd,[row binfactor dims(2:end)]);
[nd,nshift]     = shiftdim(mean(nd,2));
if nshift > 1
    nd          = shiftdim(nd,-1);  % recover leading singleton dimension if necc.
else
    nd          = squeeze(nd);      % eliminate internal singletons
end

% compute binned modulus here
if ~isempty(mod)
    mod    = mean(mod,1);
    nd     = cat(1,nd,mod);
end

% permute the matrix back to its correct shape
data   = ipermute(nd, neworder);
