function s1 = SparseNoise2D(xres,yres,frames,pixsize)
% Generates a sparse noise sequence.  An SN frame is a single pixel of black
% or white on a field of gray (neutral luminance).  Each frame can be described
% by 3 parameters (x position, y position, pixel sign).  However, if the dimensions
% of the stimulus are constant through the sequence, we can describe the basis set
% with a single signed integer parameter, which describes the position of the pixel
% (using matlab index notation), and its sign.
%
% Because SN only consists of a single pixel, we do not need to respect pixel
% boundaries as we would in white noise.  The advantage of using larger pixels
% is in increased signal from the cell, but the larger pixel will also act as
% a lowpass filter in the spatial domain.
%
% stim = SparseNoise2D(xres,yres,pixsize,frames)
%
% xres - number of x pixels
% yres - number of y pixels
% pixsize - the size (in screen pixels) to make each pixel
% frames - the number of frames to generate. This is altered if COMPLETE is defined.
%
% s1 - an s1 structure
%
% See Also:
%
%   headers/s1_struct.m   - describes the s1 structure
%   Visual/SparseFrame.m  - the mfile called to generate the stimulus frames
%
% Changes:
%
% 1.7:  a complete set is now generated and shuffled.
% 1.10: generates an s1 structure instead of s0.
%
% $Id$
COMPLETE = 1;
if nargin < 4
    [xres, yres, frames, pixsize, COMPLETE] = ask;
end

s1.type     = 's1';
s1.mfile    = 'SparseFrame';
s1.colmap   = gray(3);
s1.x_res    = xres;
s1.y_res    = yres;
s1.static   = {[xres,yres],pixsize};

states      = prod([xres,yres]);      % the number of unit vectors in the basis
                                      % (times 2 for two phases, plus 1 for pure gray)

% generate random numbers:
if COMPLETE
    compl   = -states:states;
    rep     = ceil(frames / length(compl));     % minimum # of repeats to meet frames
    param   = repmat(compl,rep,1);
    ind     = randperm(prod(size(param)));      % random indices into parameters
    param   = param(ind)';
else
    param   = unidrnd(2 * states + 1, frames, 1);
    param   = param - states - 1;
end

s1.param    = param;

% stim.stimulus = repmat(2,[s, frames]); % set to 50% gray
% p = pixsize - 1;
% for i = 1:frames
%     x = r_x(i);
%     y = r_y(i);
%     z = r_z(i) * 2 + 1; % 1 and 3
%     stim.stimulus(x:x+p,y:y+p,i) = z;
%     stim.parameters(i,:) = [x y r_z(i)];
% end

function s = output_matrix(res, pixsize)
% calculates the (flat) output matrix dimensions, 
% which depend on the modulus and magnitude of the pixel size. Pixel
% coordinates must refer to integers [x_corner, y_corner, width, height],
% so all input arguments must be integral
s = res + pixsize - 1;

% function [x, y, z, frames] = complete_stimulus(xres, yres, length)
% % calculates a complete stimulus set (shuffled)
% [X Y Z] = meshgrid(1:xres,1:yres,0:1);  % all possible pixel combinations
% frames = prod(size(X)); % number of possible frames
% repeats = ceil(length / frames);
% frame_ind = repmat(1:frames,repeats,1);             % N repeats of the pixel sequence
% frames    = prod(size(frame_ind));
% frame_ind = frame_ind(randperm(frames)); % randomly permuted index into X, Y, and Z
% x = X(frame_ind);
% y = Y(frame_ind);
% z = Z(frame_ind);

function [xres, yres, frames, pixsize, complete] = ask()
% opens a dialog box to ask values
prompt = {'X Resolution (pixels):','Y Resolution (pixels):','Frames:','Pixel Size:',...
          'Complete Set?'};
def = {'10','10','1000','1','1'};
title = 'Values for 2D White Noise';
answer = inputdlg(prompt,title,1,def);
xres = str2num(answer{1});
yres = str2num(answer{2});
frames = str2num(answer{3});
pixsize = str2num(answer{4});
complete = str2num(answer{5});