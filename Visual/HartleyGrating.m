function img = hartleygrating(dim, k)
%
% Generates a 2D grating using the Hartley basis set.  See Ringach et al 1997.
% H(kx,ky) = cas(2*pi*(kx*l + ky*m)/M), where M is the size of the image, and
% l and m are the spatial variables, with l and m between 0 and M-1.  The advantage
% of using the Hartley set is that the image can be described by two real parameters.
%
% USAGE:
% Z = hartleygrating(dim, k)
%
% k     - [X,Y] spatial frequency (wave number)
% dim   - size of the resulting image (scalar)
%
% implemented as H(k) = cas(2*pi*<k,r>/M), where <k,r> is the inner product
% of the vectors k = (kx,ky) and r = (l,m) (in Cartesian coordinates).  There
% are undoubtedly faster ways to implement this.
%
% Values are quantized to 254 discrete CLUT values.  These constants are hardcoded
% for speed
%
% $Id$

error(nargchk(2,2,nargin))

MINCOL  = 1;
MAXCOL  = 254 - 1;

sz    = dim.*dim;
l     = 0:dim-1;
[L M] = meshgrid(l,l);                      % r(l) and r(m) vectors
R     = [reshape(L,sz,1),reshape(M,sz,1)];  % R matrix

Z     = R * k' * 2 * pi / dim;         % inner product
img   = sin(Z) + cos(Z);               % P2P tends to be around 1.4
img   = round(img * MAXCOL/2/(-min(img)) + MAXCOL/2 + MINCOL);
%img   = img * 90.7 + 128;              % img * MAXCOL/2/-min(img) + MAXCOL/2 + MINCOL;
% img   = img - min(img);
% img   = round(img * (MAXCOL - MINCOL) / max(img) + MINCOL);
img   = reshape(img,dim,dim);

