function img = singrating(rho, omega, phi, dim)
%
% Generates a 2D sin grating with arbitrary orientation, frequency, and phase
%
% USAGE:
% Z = singrating(rho, theta, phi, dim)
%
% rho   - orientation, in radians
% omega - spatial frequency, in cycles per 100 pixels
% phi   - phase, in radians
% dim   - [width, height]
%
% Z = A sin (<w,r> + phi), where w and r are 2D vectors
%
% Note: SinGrating() has been deprecated.  Use HartleyGrating() instead
%
% $Id$

error(nargchk(4,4,nargin))

sz    = prod(dim);
[X Y] = meshgrid(1:dim(1),1:dim(2));    % r(x) and r(y) vectors
R = [reshape(X,sz,1),reshape(Y,sz,1)];  % R matrix
f = [omega*cos(rho), omega*sin(rho)];       % convert to cartesian coordinates
f = f * 2 * pi / 100;                   % convert to cycles per 100 pixels

Z   = R * f';                             % inner product
img = sin(Z+phi);
img = reshape(img,dim(1),dim(2));

% Z = inline('sin(dot(f,r) + p)','f','r','p');    % function
% 
% img = Z(f,[X Y],phi);