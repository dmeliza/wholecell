function CgPlayMovie(frate, syncrect, syncmap)
% Plays a movie using the coggraph toolkit.  We define a movie
% as a collection of sprites that are played at a certain frame
% rate.  This function requires the movie to have been loaded into
% video memory, and will throw an error if there are not enough sprites loaded
%
% CgPlayMovie(frate, [syncrect, [syncmap]])
% frate - the frame rate of the movie, in multiples of the refresh time
%         (e.g. if the refresh rate is 60 Hz and frate is 2, the frame rate
%          will be 30 Hz)
% syncrect - 1X4 array defining a rectangle that will serve as a sync signal
%            (that is, it changes state every frame). The dimensions are in fractions
%            of the total screen size, with the origin at the bottom left.
%            Default is [0 0 .125 .125]
% syncmap - 1X2 array defining the two colmp lookups for the on and off state
%           of the sync rectangle.
%           default is [0 1]
%
% TODO: Restrict movie to a region of the screen; make pixels non-ortho to screen.
%
% $Id$
global timing;

% check that display has been defined
gprimd = cggetdata('gpd');
if isempty(gprimd)
    error('No display has been defined.');
end

% check that frames have been loaded
a_frames = gprimd.NextRASKey - 1;
if a_frames < 1
    error('No frames have been loaded.');
end

% reset timing data and clear screen
timing = zeros(a_frames,frate);
sync = 1;
cgflip(0);
cgflip(0);
pw = gprimd.PixWidth;
ph = gprimd.PixHeight;
if nargin < 2
    syncrect = [0 0 .2 .2];
end
sr = (syncrect + [-1 -1 0 0]) .* [pw/2 ph/2 pw ph];
if nargin < 3
    syncmap = [0 1];
end
% bombs away
cgfont('Arial',10)
cgpencol(255) % should be black
t = [pw/2 - 100, ph/2 - 20];
for frame = 1:a_frames;
    for i = 1:frate
        cgdrawsprite(frame,0,0, pw, ph);
        cgrect(sr(1),sr(2),sr(3),sr(4),syncmap(sync+1));
        cgtext(num2str(frame),t);
        timing(frame,i) = cgflip;
    end
    sync = ~sync;
end
cgflip(0);
cgflip(0);