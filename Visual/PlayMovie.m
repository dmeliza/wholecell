function [] = PlayMovie(movie)
% Plays a movie using the matlab display commands.  This function
% is not designed for actual stimulus presentation, only to preview
% what a movie will look like when it is played (for instance, with CgQueueMovie
% and CgPlayMovie)
%
% Usage: PlayMovie(movie)
%
% movie - a stimulus as described by the stim_struct.m file
%
% See Also:
%
% stim_struct.m
% CgPlayMovie.m
%
%
% $Id$

error(nargchk(1,1,nargin));

% figure and colormap
run = @play;
stop = @stop;
findfig('wholecell_playmovie');
set(gcf,'UserData',movie,'buttondownfcn',run,'doublebuffer','on','color',[1 1 1]);
axes;
colormap(movie.colmap);
set(gca,'xtick',[],'ytick',[],'NextPlot','replacechildren');
play(gcf,[]);

function play(obj,event)
stop           = @stop;
set(gcf,'buttondownfcn',stop);
movie          = get(gcf,'UserData');
[X Y a_frames] = size(movie.stimulus);
CLIM           = [1 size(movie.colmap,1)];
set(gca,'xlim',[1 X],'ylim',[1 Y]);
setpref('wholecell_PlayMovie','Running',1);
for i = 1:a_frames
    h = imagesc(movie.stimulus(:,:,i),CLIM);
    set(h,'buttondownfcn',stop);
    text(1.5,1.5,num2str(i))
    if ~getpref('wholecell_PlayMovie','Running')
        break
    end
    drawnow
end
cb = @play;
set(gcf,'buttondownfcn',cb);
set(h,'buttondownfcn',cb);

function stop(obj, event)
setpref('wholecell_PlayMovie','Running',0);
