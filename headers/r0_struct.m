function [s, fields] = r0_struct()
%
% Defines the r0 structure (by returning a structure with the proper fields)
% r0 structures are used to describe episodic responses to periodic stimulation.
% Each episode is required to be the same length, and the relative timing of
% each episode is also required.
%
% Required fields:
%
% .data     - the response, which is an NxMxP array of M episodes of N samples,
%              with P channels of data
% .time     - an Nx1 vector describing the time offset of each sample (in seconds)
% .abstime  - an Mx1 vector describing the time offset of each episode (in minutes)
% .t_rate   - the sampling rate (in Hz) of the data (redundant with .time)
% .y_unit   - a character array (P rows) describing the units of each channel
%
% Optional fields:
%
% .info     - data from the source file
%
% $Id$

fields = {'data','time','abstime','t_rate','y_unit'};
C      = {[],[],[],[],''};
s      = cell2struct(C, fields, 2);
