function [s, fields] = s1_struct()
%
% Defines the s1 structure (by returning a structure with the proper fields)
% s1 structures allow stimuli to be dynamically generated during stimulus presentation;
% this is useful if the stimulus file would be much larger than could be loaded into
% memory at once, and the stimulus is easily parameterized.  
% To generate the a frame, the following code should be invoked:
% feval(s1.mfile,s1.static{:},s1.param(:,framenum)).  This, of course, requires
% the signature of mfile() to be mfile(statics{:},[frameparams])
%
% Required fields:
%
% m.mfile  - the mfile which should be executed.
% m.static - a cell array of static parameters (e.g. stimulus size)
% m.param  - an MxN array, with N parameters and M frames
% m.xlim   - the x dimension of the stimulus frames
% m.ylim   - the y dimension
% m.colmap - the colormap of the movie
%
% Optional fields:
%
% none
%
% $Id$

fields = {'mfile','static','param','xlim','ylim','colmap'};
C      = {'',{},[],[],[],[]};
s      = cell2struct(C, fields, 2);
