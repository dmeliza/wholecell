function [s, fields] = r0a_struct()
%
% Defines the r0a structure (by returning a structure with the proper fields)
% r0a structures are used to describe episodic responses to periodic stimulation.
% Each episode is required to be the same length, and the relative timing of
% each episode is also required.  They are an extension of the r0 structure, requiring
% the same fields, along with additional fields describing the statistics of the
% episodes
%
% See Also:
%   headers/r0_struct.m
%
% Required fields:
%
% All fields in r0,
% .pspdata  - Vector of data, the same size as abstime
% .irdata   - etc
% .srdata   - etc
%
% Optional fields:
%
% .info     - data from the source file
%
% $Id$

fields = {'data','time','abstime','t_rate','y_unit','pspdata','irdata','srdata'};
C      = {[],[],[],[],'',[],[],[]};
s      = cell2struct(C, fields, 2);
