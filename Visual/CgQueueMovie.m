function CgQueueMovie(movie, a_frames)
% Loads a "movie" into video memory.  This is composed of a series of sprites,
% which will be played back at a certain frame rate by CgPlayMovie.  Currently only
% 8-bit movies are supported.  Assumes that the display has already been initialized
% to 8-bit mode, so that subsequent calls to, e.g., cgloadarray, will work correctly.
%
% CgQueueMovie(movie, [a_frames])
%
% movie - the movie structure, which must have x_res, y_res, colmap, and stimulus
%         fields defined (see LoadMovie for details on this structure)
% a_frames - the number of frames to load (default = size(movie.stimulus,3))
%
% Note that the movie's colormap is loaded into slots 1-255, meaning that the movie
% can only contain 254 CLUT values.  Futhermore, entry 255 will be set to [1 1 1],
% so non-grayscale movies that use 255 will give unexpected results.
%
% $Id$

% setup colormap:
if size(movie.colmap,1) > 254
    movie.colmap = movie.colmap(:,1:254);
end
cgcoltab(1,movie.colmap);
cgnewpal;
% load sprites:
pix = movie.x_res * movie.y_res;
s = size(movie.stimulus,3);
if nargin < 2 | s < a_frames
    a_frames = s;
end
h = waitbar(0,['Loading movie (' num2str(a_frames) ' frames)']);
for i = 1:a_frames
    s = cgremap(movie.stimulus(:,:,i));
    cgloadarray(i,movie.x_res,movie.y_res,s,movie.colmap,1);
    waitbar(i/a_frames,h);
end
close(h);

function s = cgremap(s)
% remaps an array into a vector, which is necessary in order
% to pass that array to cgloadarray.
p = prod(size(s));
s = reshape(s',1,p) - 1;