function stim = WhiteNoise2D(xres,yres,frames,colmap)
% Dynamically generates 2d white noise (using rand)
% stim = WhiteNoise2D(xres,yres,frames,[zres|colmap])
%
% xres - number of x pixels
% yres - number of y pixels
% zres - generates a grayscale colormap with zres values
% colmap - the colormap (an Nx3 array)
%
% $Id$
r = rand(xres,yres,frames); % numbers are distributed between 0 and 1
if length(colmap) == 1
    N = colmap;
    colmap = gray(N);
else
    N = size(colmap,1);
end
stim.stimulus = ceil(r .* N); % integers distributed between 1 and N

stim.x_res = xres;
stim.y_res = yres;
stim.colmap = colmap;