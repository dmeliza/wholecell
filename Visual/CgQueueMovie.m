function CgQueueMovie(movie, a_frames)
% Loads a "movie" into video memory.  This is composed of a series of sprites,
% which will be played back at a certain frame rate by CgPlayMovie.  Currently only
% 8-bit movies are supported.  Assumes that the display has already been initialized
% to 8-bit mode, so that subsequent calls to, e.g., cgloadarray, will work correctly.
%
% CgQueueMovie(movie, [a_frames])
%
% movie - the movie structure, which can be either an .s0 or an .s1 structure
% a_frames - the number of frames to load (default = size(movie.stimulus,3))
%
% Note that the movie's colormap is loaded into slots 1-255, meaning that the movie
% can only contain 254 CLUT values.  Futhermore, entry 255 will be set to [1 1 1],
% so non-grayscale movies that use 255 will give unexpected results.
%
% SEE ALSO:
%
%   headers/s1_struct
%
% $Id$

% setup colormap:
if size(movie.colmap,1) > 255
    movie.colmap = movie.colmap(:,1:255);
end
cgcoltab(1,movie.colmap);
cgnewpal;
if isfield(movie,'mfile')
    % for s1 structs, just check to make sure we can load the frames
    if ~exist(movie.mfile)
        errordlg('Could not find the frame-generating function','Load Movie Failed')
        error('Could not find the frame-generating function')
    end
else
    % for s0 structures, the frames have to be pre-loaded
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
end

function s = cgremap(s)
% remaps an array into a vector, which is necessary in order
% to pass that array to cgloadarray.
p = prod(size(s));
s = reshape(s',1,p) - 1;