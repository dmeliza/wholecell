function CgPlayFrames(frate, syncrect)
% Plays a movie using the coggraph toolkit.  We define a movie
% as a collection of sprites that are played at a certain frame
% rate.  This function requires the movie to have been loaded into
% video memory, and will throw an error if there are not enough sprites loaded
%
% CgPlayMovie(frate, [syncrect])
% frate - the frame rate of the movie, in multiples of the refresh time
%         (e.g. if the refresh rate is 60 Hz and frate is 2, the frame rate
%          will be 30 Hz)
% syncrect - 1X4 array defining a rectangle that will serve as a sync signal
%            (that is, it changes state every frame). The dimensions are in fractions
%            of the total screen size, with the origin at the bottom left.
%            Default is [0 0 .125 .125]
%
% Changes:
% 1.8:      This function now commandeers colormap entries 0 and 255 for the sync
%           rectangle and the status text.  These will be set to [0 0 0] and [1 1 1]
%           respectively.  Consequently, the movie colormap can only have 254 values,
%           as it will be loaded starting in position 1, and if a 254th value is
%           supplied, it will be overwritten by CgPlayFrames
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

% look up center and size
PW          = gprimd.PixWidth;
PH          = gprimd.PixHeight;
[x y pw ph] = CGDisplay_Position;

% reset timing data and clear screen
timing = zeros(a_frames,frate);
sync = 1;
cgflip(0);
cgflip(0);
if nargin < 2
    syncrect = [0 0 .2 .2];
end
sr = (syncrect + [-1 -1 0 0]) .* [PW/2 PH/2 PW PH];
if nargin < 3
    syncmap = [0 255];
end
% set font and colormap
cgfont('Arial',10)
cgcoltab(0,[0 0 0])
cgcoltab(255,[1 1 1])
cgnewpal
cgpencol(255)
t = [PW/2 - 100, -PH/2 + 20];
% bombs away
for frame = 1:a_frames;
    for i = 1:frate
        cgdrawsprite(frame,x,y, pw, ph);
        cgrect(sr(1),sr(2),sr(3),sr(4),syncmap(sync+1));
        cgtext(num2str(frame),t(1),t(2));
        timing(frame,i) = cgflip(0);
    end
    sync = ~sync;
end
cgflip(0);
cgflip(0);