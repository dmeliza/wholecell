function [s, fields] = a1_struct()
%
% Defines the a1 structure (by returning a structure with the proper fields)
% A-type structures contain analysis data.  The a1 structure defines the results from
% analyzing a stimulus-response relationship.
%
% Required fields:
%
% m.type       - must be 'a1'
% m.stimtype   - the type of the stimulus ('s0' or 's1')
% m.kern       - the "kernel" of the system, in parameter space
%                N parameter by M frames - first order kernel
%                N parameter by M frames by P solutions - second order kernels
% m.frate      - the frame rate of the kernel (in milliseconds)
%
%
% Optional fields:
% m.stim       - the filename of the stimulus
% m.resp       - the filename of the response
% m.param      - N by J array defining the parameters corresponding to the kernel.
% m.strf       - the kernel refactored into the space-time domain.
%
%
% $Id$

fields = {'type','stimtype','kern','frate'};
C      = {'a1','',[],[]};
s      = cell2struct(C, fields, 2);
