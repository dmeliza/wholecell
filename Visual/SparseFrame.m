function Z = SparseFrame(dim, pixsize, param)
%
% Generates a 2D stimulus sparse noise stimulus frame, which consists of a single
% pixel with either more or less luminance than the background. Pixels can be any
% positive nonzero integer size, although values other than 1 result in a basis set
% with a lowpass bias.
%
% USAGE:
% Z  = SparseFrame(dim, pixsize, param)
%
% dim       - the dimensions of the stimulus array (pixel corners) (2 element vector)
% pixsize   - the size of the pixel (natural number)
% param     - a integer scalar that must be between -prod(dim) and prod(dim)
%
% If pixsize is > 1, the matrix returned will be larger than dim.
%
% See Also:
%
% Visual/SparseNoise2D.m    - generates sequences for this function
%
% $Id$

ON  = 3;
NEU = 2;
OFF = 1;

val = (param > 0)*ON + (param==0)*NEU + (param < 0)*OFF;    % pick the value to assign

if pixsize == 1                         % fast generate the simplest case
    Z        = repmat(NEU,dim);
    Z(param) = val;
else
    p       = pixsize - 1;
    sz      = dim + p;                  % correct for larger pixels
    Z       = repmat(NEU,sz);
    [i,j]   = ind2sub(dim,abs(param));  % convert to i,j indices
    Z(i:i+p,j:j+p) = val;
end
