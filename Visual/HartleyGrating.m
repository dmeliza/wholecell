function Z = hartleygrating(dim, k)
%
% Generates a 2D grating using the Hartley basis set.  See Ringach et al 1997.
% H(kx,ky) = cas(2*pi*(kx*l + ky*m)/M), where M is the size of the image, and
% l and m are the spatial variables, with l and m between 0 and M-1.  The advantage
% of using the Hartley set is that the image can be described by two real parameters.
%
% USAGE:
% Z = hartleygrating(dim, k)
%
% k     - [X,Y] spatial frequency (integral wave number)
% dim   - size of the resulting image (scalar)
%
% implemented using the Bracewell (1984 Proc IEEE) fast Hartley transform, which
% defines H(t) as real(fft(t)) - imag(fft(t)).  This is roughly 3 times as fast
% as using the canonical cas() formula.  One consequence of this is that only
% integral wavenumbers can be used.
%
% Values are quantized to 254 discrete CLUT values.  Unfortunately this is also
% a computational annoyance because the amplitude of the hartley transform is
% not constant.  We can afford to be fudgy as the display doesn't have a very linear
% luminance curve anyway, but the fix() operation takes almost as long as the fftn()...
%
% $Id$

error(nargchk(2,2,nargin))

MINCOL  = 1;
MAXCOL  = 254-1;

% implementation using the Bracewell FHT
dd                = dim*dim;
Y                 = zeros(dim,dim);                       % hartley space
ind               = (k < 0).*(dim+k+1) + (k >= 0).*(k+1); % fix negative wavenumbers
Y(ind(1),ind(2))  = 5;                                    % all power at supplied k
Z                 = fftn(Y);
Z                 = (real(Z) - imag(Z))/dd;
m                 = -min(min(Z));
Z                 = (Z + m) * MAXCOL/m/2 + MINCOL;
Z                 = double(uint8(Z));                     % 3x as fast as fix()
