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
% m.group - if responses should be grouped together (e.g. different spatial frequencies
%           at the same orientation), this field should be supplied. It consists
%           of an array in which stimulus frame numbers are grouped in rows.
%           For instance, for the following groups [1 2] [3 4] [5 6 7], m.group = 
%           [1 2 0
%            3 4 0
%            5 6 7].  Note that frame #1 is m.stimulus(:,:,2)
%
% $Id$

fields = {'type','colmap','stimulus','x_res','y_res'};
C      = {'s2',[],[],[],[]};
s      = cell2struct(C, fields, 2);
