function [] = abf2mat(filename, episodeInterval, channels)
% ABF2MAT: reads in an Axon Binary File and writes out a matfile containing
% an r0 structure. Just a wrapper for ABF2R0
%
% abf2mat(filename, episodeInterval, [channels])
%
% See also headers/r0_struct.m
%          Analysis/ABF2MAT.m
%
% Copyright C. Daniel Meliza 2002-2005
% Free for use under a Creative Commons Attribution Licence
% (http://creativecommons.org/licenses/by/2.0/)
%
% $Id$

error(nargchk(2,3,nargin));

if nargin > 2
    r0  = abf2r0(filename, episodeInterval, channels);
else
    r0  = abf2r0(filename, episodeInterval);
end

% compress the data and time fields to singles since it's very unlikely
% that we have more than 16 bits on the ADC, or that we need that much
% precision
r0.data = single(r0.data);
r0.time = single(r0.time);

[path basename] = fileparts(filename);
fn              = [basename '.mat'];
writestructure(fn, r0);