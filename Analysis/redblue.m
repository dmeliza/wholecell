function h = redblue(alpha,m)
%REDBLUE    Red-white-blue color map.
%   REDBLUE(ALPHA,M) returns an M-by-3 matrix containing a "redblue" colormap.
%            The paramter ALPHA controls the amount of the map that is not white
%   REDBLUE(ALPHA) is the same length as the current colormap.
%   REDBLUE, by itself, has a default alpha of 1 (3/8 of colormap is white)
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(redblue)
%
%   See also HSV, GRAY, PINK, COOL, BONE, COPPER, FLAG, 
%   COLORMAP, RGBPLOT.


%   $Id$

if nargin < 2, m = size(get(gcf,'colormap'),1); end
if nargin < 1, alpha = 3/8; end
n = fix(m*alpha);

r = [(1:n)'/n; ones(m-n,1)];
b = [ones(m-n,1); flipud((1:n)')/n];
g = r + b - 1;

h = [r g b];
