function [s, fields] = stim_struct()
%
% Defines the stimulus structure (by returning a structure with the proper fields)
%
% Required fields:
%
% m.colmap - the color mappings for each value in the stimulus 
%            (Nx3 array, N == max(max(m.stimulus)))
% m.stimulus - the movie, which should be an x_res by y_res by n_frames array of doubles
%
% Optional fields:
%
% m.x_res - the number of (parameter) x pixels (scalar)
% m.y_res - the number of (parameter) y pixels (scalar)
% m.parameters - for parameterized stimuli, a J-by-n_frames array of stimulus parameters
%
% $Id$

fields = {'colmap','stimulus','x_res','y_res','parameters'};
C      = cell(length(fields),1);
s      = cell2struct(C, fields, 1);
