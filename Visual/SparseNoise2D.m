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
% frames - the number of frames to generate (default is the complete mseq)
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
r_x = ceil(rand(1,frames) .* xres); % x corner of pixel (1 to xres)
r_y = ceil(rand(1,frames) .* yres); % y corner of pixel (1 to yres)
r_z = round(rand(1,frames)); % luminance of pixel (0 or 1)

stim.stimulus = repmat(2,[s, frames]); % set to 50% gray
p = pixsize - 1;
for i = 1:frames
    x = r_x(i);
    y = r_y(i);
    z = r_z(i) * 2 + 1; % 1 and 3
    stim.stimulus(x:x+p,y:y+p,i) = z;
end

function s = output_matrix(res, pixsize)
% calculates the (flat) output matrix dimensions, 
% which depend on the modulus and magnitude of the pixel size. Pixel
% coordinates must refer to integers [x_corner, y_corner, width, height],
% so all input arguments must be integral
s = res + pixsize - 1;

% pixel centers
% if pixsize == 1
%     s = [xres yres];
% elseif mod(pixsize,2) == 0
%     p = pixsize/2;
%     s = [xres+p, yres+p];
% else
%     % fix this later for other moduli
%     error('pixsize must be 1 or a multiple of 2');
% end
    