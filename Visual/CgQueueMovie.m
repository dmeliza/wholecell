function seq = CgQueueMovie(movie, a_frames)
% Loads a "movie" into video memory.  This is composed of a series of sprites,
% which will be played back at a certain frame rate by CgPlayMovie.  Currently only
% 8-bit movies are supported.  Assumes that the display has already been initialized
% to 8-bit mode, so that subsequent calls to, e.g., cgloadarray, will work correctly.
%
% seq = CgQueueMovie(movie, [a_frames])
%
% movie - the movie structure, which can be either an .s0 or an .s1 structure
% a_frames - the number of frames to load (default = length of sequence)
% seq   - the sequence of sprites to play, which in the case of .s0 will just be 1:end,
%         but in the case of an s1 structure, will be an index into the set of unique
%         images in the sequence
%
% Note that the movie's colormap is loaded into slots 1-255, meaning that the movie
% can only contain 254 CLUT values.  Futhermore, entry 255 will be set to [1 1 1],
% so non-grayscale movies that use 255 will give unexpected results.
%
% SEE ALSO:
%
%   headers/s0_struct
%   headers/s1_struct
%
% $Id$

% setup colormap:
if size(movie.colmap,1) > 255
    movie.colmap = movie.colmap(:,1:255);
end
cgcoltab(1,movie.colmap);
cgnewpal;
if strcmpi(movie.type,'s1')
    % for s1 structs, we want to load all the unique images into video memory,
    % then return the sequence in which those images ought to be displayed
    if ~exist(movie.mfile)
        errordlg('Could not find the frame-generating function','Load Movie Failed')
        error('Could not find the frame-generating function')
    else
        p        = movie.param(1:a_frames,:);        % number of frames asked for
        [a b c]  = unique(p,'rows');                 % a(c) = p;
        a_frames = length(b);                        % number of unique frames
        h = waitbar(0,['Loading unique (' num2str(a_frames) ' frames)']);
        for i = 1:a_frames
            Z     = feval(movie.mfile,movie.static{:},p(i,:));
            [X,Y] = size(Z);
            cgloadarray(i,X,Y,reshape(Z',1,X*Y),movie.colmap,1);   % load sprites
            waitbar(i/a_frames,h);
        end
        seq      = c;
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
    seq = 1:a_frames;
    close(h);
end

function s = cgremap(s)
% remaps an array into a vector, which is necessary in order
% to pass that array to cgloadarray.
p = prod(size(s));
s = reshape(s',1,p) - 1;