function stim = SparseNoise2D(xres,yres,frames,pixsize)
% Dynamically generates 2D sparse noise (using rand).
% Because sparse noise only consists of one pixel per frame, we do not
% have to respect pixel boundaries in the way that we do in white noise.
% Pixel size is independent of the number of pixel centers.
% Pixels will be either black or white, against a gray backdrop.
%
% stim = SparseNoise2D(xres,yres,pixsize,frames)
%
% xres - number of x pixels
% yres - number of y pixels
% pixsize - the size (in screen pixels) to make each pixel
% frames - the number of frames to generate. If 0, generates a complete set (each pixel
%          gets one black and one white frame)
%
% stim - the stimulus structure, which has the following fields:
%   x_res
%   y_res
%   colmap
%   stimulus
%   parameters  (Nx3 array, giving the x,y location of each pixel and its color)
%
% $Id$
error(nargchk(4,4,nargin));

% colormap:
stim.colmap = gray(3);
% stimulus dimensions:
s = output_matrix([xres yres], pixsize); 
stim.x_res = s(1);
stim.y_res = s(2);
% random numbers:
if frames == 0
    [r_x, r_y, r_z, frames] = complete_stimulus(xres, yres);
else
    r_x = ceil(rand(1,frames) .* xres); % x corner of pixel (1 to xres)
    r_y = ceil(rand(1,frames) .* yres); % y corner of pixel (1 to yres)
    r_z = round(rand(1,frames)); % luminance of pixel (0 or 1)
end

stim.stimulus = repmat(2,[s, frames]); % set to 50% gray
p = pixsize - 1;
for i = 1:frames
    x = r_x(i);
    y = r_y(i);
    z = r_z(i) * 2 + 1; % 1 and 3
    stim.stimulus(x:x+p,y:y+p,i) = z;
    stim.parameters(i,:) = [x y r_z(i)];
end

function s = output_matrix(res, pixsize)
% calculates the (flat) output matrix dimensions, 
% which depend on the modulus and magnitude of the pixel size. Pixel
% coordinates must refer to integers [x_corner, y_corner, width, height],
% so all input arguments must be integral
s = res + pixsize - 1;

function [x, y, z, frames] = complete_stimulus(xres, yres)
% calculates a complete stimulus set (shuffled)
[X Y Z] = meshgrid(1:xres,1:yres,0:1);  % all possible pixel combinations
frames = prod(size(X)); % number of possible frames
frame_ind = randperm(frames); % randomly permuted index into X, Y, and Z
x = X(frame_ind);
y = Y(frame_ind);
z = Z(frame_ind);

