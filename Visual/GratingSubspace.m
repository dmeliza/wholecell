function s1 = GratingSubspace(dim,wn,num,repeats)
%
% Generates a complete sampling of the hartley basis set between
% between a minimum and a maximum wavenumber, using all the integral wavenumbers
% between [0,wn].
%
% USAGE: s0 = GratingSubspace(dim,wn,[num,[repeats]])
%
% dim       - size of square images to generate
% wn        - max wavenumber
% num       - how densely to saturate the plane. default is 1, which includes
%             every integral wavenumber between -wn and +wn.  If this is 2,
%             every other value will be skipped, etc.
% repeats   - the number of sequences to generate (default 1)
% 
% s1 - stimulus structure
%
% Changes:
%
% the FHT used now by HartleyGrating() only accepts integral wavenumbers, so
% we check for that and only generate integral parameter values now
%
% $Id$

MFILE   = 'hartleygrating';

% check arguments
error(nargchk(0,4,nargin))
if nargin < 2
    [dim, wn, num, repeats] = ask;
elseif nargin < 3
    num = 1;
    repeats = 1;
elseif nargin < 4
    repeats = 1;
end
dim = fas(dim);
num = fas(num);
wn  = fas(wn);
repeats = fas(repeats);


MINCOL  = 1;       % minimum CLUT value
MAXCOL  = 255;     % maximum CLUT value

kx      = -wn:num:wn;
ky      = kx;
frames  = length(kx)^2;

% parameter space:
[X Y]   = meshgrid(kx, ky);
params  = [reshape(X,frames,1), reshape(Y,frames,1)];

% shuffled indices into parameter space:
ind     = repmat(1:frames,repeats,1);
indind  = randperm(frames*repeats);
ind     = ind(indind);

s1        = struct('mfile',MFILE,'param',params(ind,:),'x_res',dim,'y_res',dim,...
                   'colmap',gray(MAXCOL-MINCOL+1));
s1.static = {dim}; 

        
function [dim, frequency, num, repeats] = ask()
% opens a dialog box to ask values
prompt = {'Resolution (pixels):',...
        'Max Spatial Frequency (wavenumber):',...
        'Tiling density (1 == all):',...
        'Sequence Repeats:'};
def = {'100','9','1','1'};
title = 'Values for 2D Gratings';
answer = inputdlg(prompt,title,1,def);
dim = str2num(answer{1});
frequency = str2num(answer{2}); 
num = str2num(answer{3});
repeats = str2num(answer{4});

function num = fas(in)
% converts a number into an unsigned integer
num = fix(abs(in));