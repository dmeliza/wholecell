function Z = MakeBar(length, width, angle, option)
% Generates an array with an image of a bar.  0 is off, 1 is on.
% 
% USAGE:
%   Z = MakeBar(length, width, angle, [option])
%
%   length - number of pixels the bar is long
%   width  - number of pixels the bar is wide
%   angle  - angle to draw the bar at, should be between [0, 180)
%   option - if 'draw', plots the bar in a window
%  
% $Id$
error(nargchk(3,4,nargin))
if angle > 90
    theta = 180 - angle;
else
    theta = angle;
end
theta = theta/180 * pi;
s     = abs(sin(theta));
c     = abs(cos(theta));
X     = ceil(width * s + length * c);     % width of sprite
Y     = ceil(width * c + length * s);     % height of sprite
if angle == 90 | angle == 0
    Z = ones(Y,X);                  % special case where tangent is undefined
else
    Z     = zeros(Y,X,4);
    [x y] = meshgrid(0:X-1,0:Y-1);  % coordinates
    f     = inline('a + A * m','a','A','m');
    xcept    = width * s;
    ycept    = width * c;
    Z(:,:,1) = y <= f(ycept, x, tan(theta));
    Z(:,:,2) = y >= f(ycept - width / c, x, tan(theta));
    Z(:,:,3) = y >= f(ycept, x, -1/tan(theta));
    Z(:,:,4) = y <= f(ycept + length / s, x, -1/tan(theta));
    Z        = prod(Z,3);
    if angle > 90
        Z    = fliplr(Z);
    end
%     figure
%     hold on
%     x = 0:X-1;
%     plot(x,f(ycept, x, tan(angle)),'b')
%     plot(x,f(ycept - width / c, x, tan(angle)),'g')
%     plot(x,f(ycept, x, -1/tan(angle)),'r')
%     plot(x,f(ycept + length / s, x, -1/tan(angle)),'k')
end
if nargin > 3
    figure,imagesc(Z)
    axis square
    axis xy
end
