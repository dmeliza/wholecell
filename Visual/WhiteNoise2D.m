function stim = WhiteNoise2D(xres,yres,frames,colmap)
% Dynamically generates 2d white noise (using rand)
%
% Usage:
% stim = WhiteNoise2D(xres,yres,frames,[zres|colmap])
%
% xres - number of x pixels
% yres - number of y pixels
% zres - generates a grayscale colormap with zres values
% colmap - the colormap (an Nx3 array)
%
% stim - an s0 structure
%
% See Also:
%
%   headers/s0_struct
%
% If no parameters are supplied, a dialogbox is opened
%
% $Id$
if nargin < 3
    [xres yres frames colmap] = ask;
end
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
stim.type = 's0';

function [xres, yres, frames, zres] = ask()
% opens a dialog box to ask values
prompt = {'X Resolution (pixels):','Y Resolution (pixels):','Frames:','Z values:'};
def = {'6','6','1000','2'};
title = 'Values for 2D White Noise';
answer = inputdlg(prompt,title,1,def);
xres = str2num(answer{1});
yres = str2num(answer{2});
frames = str2num(answer{3});
zres = str2num(answer{4});