function [s, fields] = s1_struct()
%
% Defines the s1 structure (by returning a structure with the proper fields)
% s1 structures allow stimuli to be dynamically generated during stimulus presentation;
% this is useful if the stimulus file would be much larger than could be loaded into
% memory at once.  Execution of the 
%
% Required fields:
%
% m.mfile  - the mfile which should be executed.
% m.parameters - a cell array of values which should be passed to the mfile
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
