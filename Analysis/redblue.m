function h = redblue(alpha,m, mu)
%REDBLUE    Red-white-blue color map.
%   REDBLUE(ALPHA,M,[MU]) returns an M-by-3 matrix containing a "redblue" colormap.
%            The paramter ALPHA controls the amount of the map that is not
%            white.  A value of 1 leaves no white.
%            MU is used when the zero point of the colormap is not in 
%            the precise middle. It should reside in [-1 1], and the
%            default is 0
%
%   REDBLUE(ALPHA) is the same length as the current colormap.
%   REDBLUE, by itself, has a default alpha of .187 (3/8 of colormap is white)
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(redblue)
%
%   See also HSV, GRAY, PINK, COOL, BONE, COPPER, FLAG, 
%   COLORMAP, RGBPLOT.


%   $Id$

if nargin < 2, m = size(get(gcf,'colormap'),1); end
if nargin < 1, alpha = 3/16; end
if nargin < 3 
    mu = 0;
end

% convert parameters to useful indices
MU = fix(mu * m/2 + m/2);       % if mu is zero, MU is in the center of the map
n  = fix(m*alpha/2);            % this is the number of points to leave white

if length(n)==1
    n   = [n n];
end
nr = MU - n(1);
nb = MU + n(2);

r = [(1:nr)'/nr; ones(m-nr,1)];
b = [ones(nb,1); flipud((1:(m-nb))')/(m-nb)];
g = r + b - 1;

h = [r g b];
