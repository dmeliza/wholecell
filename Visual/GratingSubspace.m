function s0 = GratingSubspace(dim,frequency,repeats)
%
% Generates a random sampling of the grating basis set between
% two spatial frequencies.
%
% USAGE: s0 = GratingSubspace(dim,frequency,[repeats])
%
% dim - [width height]
% frequency - [minfreq, maxfreq] (in cycles per 100 pixels)
% repeats - the number of sequences to generate (default 1)
% 
% s0 - stimulus structure
%
% $Id$
error(nargchk(0,3,nargin))
if nargin < 2
    [dim, frequency, repeats] = ask;
elseif nargin < 3
    repeats = 1;
end

NORIENT = 20;      % sample x orientations between 0 and pi
NPHASE  = 2;       % sample x phases between 0 and pi/2
NFREQ   = 20;      % sample x frequencies between lowest and higesth
MINCOL  = 1;       % minimum CLUT value
MAXCOL  = 255;     % maximum CLUT value

rho     = 0:pi/(NORIENT):pi;
rho     = rho(1:end-1); % discard pi==0
phi     = [0 pi/2];
omega   = frequency(1):diff(frequency)/(NFREQ-1):frequency(2);


frames  = prod([NORIENT, NPHASE, NFREQ]);
% parameter space:
[R O P] = meshgrid(rho, omega, phi);
params  = [reshape(R,frames,1), reshape(O,frames,1), reshape(P,frames,1)];
clear R P O rho omega phi
% shuffled indices into parameter space:
ind     = repmat(1:frames,repeats,1);
indind  = randperm(frames*repeats);
ind     = ind(indind);

% evil loop, with clutting:
s = zeros([dim(1) dim(2) frames]);
for i = 1:length(ind)
    p = params(ind(i),:);
    S        = SinGrating(p(1),p(2),p(3),dim);
    S        = S - min(min(S));
    s(:,:,i) = round(S * (MAXCOL-MINCOL) / max(max(S)) + MINCOL);
end

% package it up, which also compresses s:
s0 = struct('colmap',gray(MAXCOL-MINCOL+1),'stimulus',s,'x_res',dim(1),'y_res',dim(2),...
            'parameters',params(ind,:));
        
function [dim, frequency, repeats] = ask()
% opens a dialog box to ask values
prompt = {'X Resolution (pixels):','Y Resolution (pixels):',...
        'Min Spatial Frequency (cycles/100 pixels):',...
        'Max Spatial Frequency (cycles/100 pixels);',...
        'Sequence Repeats:'};
def = {'100','100','1','20','1'};
title = 'Values for 2D Gratings';
answer = inputdlg(prompt,title,1,def);
dim = [str2num(answer{1}) str2num(answer{2})];
frequency = [str2num(answer{3}) str2num(answer{4})];
repeats = str2num(answer{5});