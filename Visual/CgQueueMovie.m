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
% Prior to version 1.10, the graphics card was accessed in palette mode.  However,
% truecolor operations, in particular, scaling, seem to be a lot faster, so all color
% lookup operations have been replaced by truecolor references.  Movies are still
% sent with a colormap, but the main difference is that there are no longer any restrictions
% on the size of the colormap.
%
% An additional side effect of switching to truecolor is that the scaling invoked by
% cgdrawsprite uses a different interpolation algorhythm (Palette mode uses a
% nearest-neighbor method that preserves sharp boundaries nicely).  This is probably
% a function of the directx backend as I can find no way to turn it off.  Thus, in order
% to avoid severely distorting the frames, we have to use the cgloadsprite scaler to
% scale images up to at least 100 pixels.
%
% SEE ALSO:
%
%   headers/s0_struct
%   headers/s1_struct
%
% $Id$

if strcmpi(movie.type,'s1')
    % for s1 structs, we want to load all the unique images into video memory,
    % then return the sequence in which those images ought to be displayed
    if ~exist(movie.mfile)
        errordlg('Could not find the frame-generating function','Load Movie Failed')
        error('Could not find the frame-generating function')
    else
        if nargin > 1
            p        = movie.param(1:a_frames,:);        % number of frames asked for
        else
            p       = movie.param;
        end
        [a b c]  = unique(p,'rows');                 % a(c) = p;
        a_frames = length(b);                        % number of unique frames
        h = waitbar(0,['Loading unique frames (' num2str(a_frames) '/' num2str(length(c)) ')']);
        for i = 1:a_frames
            Z     = feval(movie.mfile,movie.static{:},p(i,:));
            dim   = size(Z);
            dim2  = dim .* ceil(100./dim);            % nice integer scaleup
            cgloadarray(i,dim(1),dim(2),reshape(Z',1,prod(dim)),movie.colmap,dim2(1),dim2(2));
            waitbar(i/a_frames,h);
        end
        seq      = c;
        close(h);
    end
else
    % for s0 structures, the frames have to be pre-loaded
    s = size(movie.stimulus,3);
    if nargin < 2 | s < a_frames
        a_frames = s;
    end
    h = waitbar(0,['Loading movie (' num2str(a_frames) ' frames)']);
    for i = 1:a_frames
        s = movie.stimulus(:,:,i);
        dim   = size(s);
        dim2  = dim .* ceil(100./dim);            % nice integer scaleup
        s = cgremap(movie.stimulus(:,:,i));
        cgloadarray(i,movie.x_res,movie.y_res,s,movie.colmap,dim2(1),dim2(2));      % dc mode
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