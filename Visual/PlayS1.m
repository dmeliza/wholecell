function [] = PlayS1(movie)
% Plays a movie using the matlab display commands.  This function
% is not designed for actual stimulus presentation, only to preview
% what a movie will look like when it is played (for instance, with CgQueueMovie
% and CgPlayMovie)
%
% Usage: PlayS1(movie)
%
% movie - a stimulus as described by the s1_struct.m file
%
% See Also:
%
% s1_struct.m
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
movie           = get(gcf,'UserData');
mfile           = movie.mfile;
param           = movie.param;
[frames params] = size(param);
set(gca,'xlim',[1 movie.x_res],'ylim',[1 movie.y_res]);
setpref('wholecell_PlayMovie','Running',1);
for i = 1:frames
    Z    = feval(mfile,movie.static{:},param(i,:));
    h    = imagesc(Z);
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
