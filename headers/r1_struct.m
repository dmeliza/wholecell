function [s, fields] = r1_struct()
%
% Defines the r1 structure (by returning a structure with the proper fields)
% r1 structures are used to describe multiple responses to a similar stimulation.
% Unlike r0 structures, no constraint is placed on response length, and the
% relative timing of each episode is ignored.  r1 structures are implemented
% as structure arrays, with each element of the array representing a single repeat
%
% Required fields:
%
% .data     - the response, which is an NxP array of N samples with P channels of data
% .timing   - a synchronization "channel" which represents the times at which
%           - the stimulus changed frames
% .t_rate   - the sampling rate (in Hz) of the data
% .y_unit   - a character array (P rows) describing the units of each channel
%
% Optional fields:
%
% .info     - data from the source file
%
% $Id$

fields = {'data','timing','t_rate','y_unit'};
C      = {[],[],[],''};
s      = cell2struct(C, fields, 2);
