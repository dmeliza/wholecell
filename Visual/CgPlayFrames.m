function CgPlayFrames(frate, seq)
% Plays a movie using the coggraph toolkit.  We define a movie
% as a collection of sprites that are played at a certain frame
% rate.  This function requires the movie to have been loaded into
% video memory, and will throw an error if there are not enough sprites loaded
%
% CgPlayMovie(frate, seq)
% frate - the frame rate of the movie, in multiples of the refresh time
%         (e.g. if the refresh rate is 60 Hz and frate is 2, the frame rate
%          will be 30 Hz)
% seq   - The sequence of sprites to play (column of indices).  Values must not exceed
%         the number of sprites actually loaded in video memory.
%
% Changes:
% 1.8:      This function now commandeers colormap entries 0 and 255 for the sync
%           rectangle and the status text.  These will be set to [0 0 0] and [1 1 1]
%           respectively.  Consequently, the movie colormap can only have 254 values,
%           as it will be loaded starting in position 1, and if a 254th value is
%           supplied, it will be overwritten by CgPlayFrames
%
% 1.10:     Now supports s1 structures. Syncrect is hard-coded.
%
% 1.13:     s1 frames are now preloaded, but only the unique ones
%
% $Id$

% check that display has been defined
gprimd = cggetdata('gpd');
if isempty(gprimd)
    error('No display has been defined.');
end

% check that enough frames have been loaded
a_frames = gprimd.NextRASKey - 1;
if a_frames < max(seq)
    error('Not enough frames have been loaded.');
end

% look up center and size
PW          = gprimd.PixWidth;
PH          = gprimd.PixHeight;
[x y pw ph] = CGDisplay_Position;

% reset timing data and clear screen
sync = 1;
cgflip(0);
cgflip(0);
syncrect = [0 0 .2 .2];
sr = (syncrect + [-1 -1 0 0]) .* [PW/2 PH/2 PW PH];
syncmap = [0 255];

% set font and colormap
cgfont('Arial',10)
cgcoltab(0,[0 0 0])
cgcoltab(255,[1 1 1])
cgnewpal
cgpencol(255)
t = [PW/2 - 100, -PH/2 + 20];

% now iterate through the sprites in the sequence
for frame = seq;
    cgdrawsprite(frame,x,y, pw, ph);
    cgrect(sr(1),sr(2),sr(3),sr(4),syncmap(sync+1));
    cgtext(num2str(frame),t(1),t(2));
    cgflip(0);    
    for i = 1:frate-1
        cgnewpal;                       % with no new frame to display this is fastest
    end
    sync = ~sync;
end
% else
%     a_frames = size(s1.param,1);
%     for frame = 1:a_frames
%         Z     = feval(s1.mfile,s1.static{:},s1.param(frame,:));
%         [X,Y] = size(Z);
%         cgloadarray(2,X,Y,reshape(Z',1,X*Y),s1.colmap,1);
%         cgdrawsprite(2,x,y, pw, ph);
%         cgrect(sr(1),sr(2),sr(3),sr(4),syncmap(sync+1));
%         cgtext(num2str(frame),t(1),t(2));
%         cgflip(0);
%         for i = 1:frate-1
%             cgnewpal;                   % this should be sync'd with the display
%         end
%         sync = ~sync;
%     end
% end

% clear screen at end
cgflip(0);
cgflip(0);