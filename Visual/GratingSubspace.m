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
error(nargchk(2,3,nargin))
if nargin < 3
    repeats = 1;
end

NORIENT = 20;      % sample x orientations between 0 and pi
NPHASE  = 2;       % sample x phases between 0 and pi/2
NFREQ   = 20;      % sample x frequencies between lowest and higesth

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

% evil loop:
s = zeros([dim(1) dim(2) frames]);
for i = 1:length(ind)
    p = params(ind(i),:);
    s(:,:,i) = SinGrating(p(1),p(2),p(3),dim);
end
clear params ind

% CLUT s
s = s - min(min(min(s)));
s = s * 255 / max(max(max(s)));
s = round(s);

% package it up:
s0 = struct('colmap',gray(255),'stimulus',s,'x_res',dim(1),'y_res',dim(2));