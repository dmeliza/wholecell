function PlayMovie(movie)
% Plays a movie using the matlab display commands.  This function
% is not designed for actual stimulus presentation, only to preview
% what a movie will look like when it is played (for instance, with CgQueueMovie
% and CgPlayMovie)
%
% PlayMovie(movie)
%
%
% $Id$

error(nargchk(1,1,nargin));

% figure and colormap
run = @play;
figure;
set(gcf,'UserData',movie,'buttondownfcn',run,'doublebuffer','on','color',[1 1 1]);
axes;
colormap(movie.colmap);
set(gca,'xtick',[],'ytick',[],'NextPlot','replacechildren');
play(gcf,[]);

function play(obj,event)
movie = get(obj,'UserData');
pix = movie.x_res * movie.y_res;
a_frames = size(movie.stimulus,3);
CLIM = [1 size(movie.colmap,1)];
for i = 1:a_frames
    imagesc(movie.stimulus(:,:,i),CLIM)
    pause(0.1)
end