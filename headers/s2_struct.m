function [s, fields] = s2_struct()
%
% Defines the stimulus structure (by returning a structure with the proper fields).
% The S2 stimulus structure defines a set of frames which are to be displayed
% to the animal, usually in a shuffled sequence.
%
% Required fields:
%
% m.type   - must be 's2'
% m.colmap - the color mappings for each value in the stimulus 
%            (Nx3 array, N == max(max(m.stimulus)))
% m.stimulus - the frame array, with dimensions of x_res by y_res by (n_frames+1)
%              The initial frame is displayed as background
%
% Optional fields:
%
% m.x_res - the number of (parameter) x pixels (scalar)
% m.y_res - the number of (parameter) y pixels (scalar)
%
% $Id$

fields = {'type','colmap','stimulus','x_res','y_res',};
C      = {'s2',[],[],[],[]};
s      = cell2struct(C, fields, 2);
