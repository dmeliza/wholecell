function [s, fields] = s2_struct()
%
% Defines the stimulus structure (by returning a structure with the proper fields)
%
% Required fields:
%
% m.type   - must be 's2'
% m.colmap - the color mappings for each value in the stimulus 
%            (Nx3 array, N == max(max(m.stimulus)))
% m.stimulus - the movie, which should be an x_res by y_res by n_frames array of doubles
% m.sequence - a row vector of indices into the stimulus field (0 is valid == blank)
%
% Optional fields:
%
% m.x_res - the number of (parameter) x pixels (scalar)
% m.y_res - the number of (parameter) y pixels (scalar)
% m.parameters - for parameterized stimuli, a J-by-n_frames array of stimulus parameters
%
% $Id$

fields = {'type','colmap','stimulus','sequence','x_res','y_res','parameters'};
C      = {'s0',[],[],[],[],[],[]};
s      = cell2struct(C, fields, 2);
