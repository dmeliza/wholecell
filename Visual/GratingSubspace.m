function s1 = GratingSubspace(dim,wn,num,repeats)
%
% Generates a complete sampling of the hartley basis set between
% between a minimum and a maximum wavenumber.
%
% USAGE: s0 = GratingSubspace(dim,wn,[num,[repeats]])
%
% dim       - size of square images to generate
% wn        - max wavenumber
% num       - the number of kx or ky values to generate (# of parameters = num^2)
%             default is 10
% repeats   - the number of sequences to generate (default 1)
% 
% s1 - stimulus structure
%
% $Id$

MFILE   = 'hartleygrating';

error(nargchk(0,4,nargin))
if nargin < 2
    [dim, wn, num, repeats] = ask;
elseif nargin < 3
    num     = 10;
elseif nargin < 4
    num     = 10;
    repeats = 1;
end

MINCOL  = 1;       % minimum CLUT value
MAXCOL  = 255;     % maximum CLUT value

kx      = -wn:2*wn/(num-1):wn;
ky      = kx;
frames  = num*num;

% parameter space:
[X Y]   = meshgrid(kx, ky);
params  = [reshape(X,frames,1), reshape(Y,frames,1)];

% shuffled indices into parameter space:
ind     = repmat(1:frames,repeats,1);
indind  = randperm(frames*repeats);
ind     = ind(indind);

s1        = struct('mfile',MFILE,'param',params(ind,:),'xlim',dim,'ylim',dim,...
                   'colmap',gray(MAXCOL-MINCOL));
s1.static = {dim}; 

        
function [dim, frequency, num, repeats] = ask()
% opens a dialog box to ask values
prompt = {'Resolution (pixels):',...
        'Max Spatial Frequency (wavenumber):',...
        'Number of frequencies:',...
        'Sequence Repeats:'};
def = {'100','9','10','1'};
title = 'Values for 2D Gratings';
answer = inputdlg(prompt,title,1,def);
dim = str2num(answer{1});
frequency = str2num(answer{2}); 
num = str2num(answer{3});
repeats = str2num(answer{4});