function [resp, str] = LoadResponseFile(filename)
%
% This function is a wrapper that will attempt to load a response from an .r0
% or .r1 file.  Depending on the file format, the data is post-processed to extract
% relevant timing (e.g.) data.  In addition, a string description is returned, which
% is used to describe load errors.
%
% Usage: [resp, str] = LoadResponseFile(filename)
%
% filename - path or filename of response file
% 
% resp     - the response structure (empty in errors)
% str      - a string describing the response properties (or the error)
%
% See Also:     headers/r0_struct.m
%               headers/r1_struct.m
%
% $Id$

error(nargchk(1,1,nargin));
resp = [];
err = [];
% Check Existence of File
if exist(filename,'file') == 0
    err = 'File does not exist';
end

% Load File
try
    r   = load('-mat',filename);
catch
    err = 'File is not a MAT file';
end

% load the first field in the structure (r0 and r1 files contain a single variable = struct)
fn    = fieldnames(r);
resp  = getfield(r,fn{1});

% Write description
[pn fn ext] = fileparts(filename);
switch lower(ext)
case '.r0'
    try
%        resp    = r.r0;
        [N M P] = size(getfield(resp,'data'));
        [T]     = size(getfield(resp,'time'),1);
        [AT]    = size(getfield(resp,'abstime'),1);
        units   = getfield(resp,'y_unit');
        t_rate  = getfield(resp,'t_rate');
        str     = sprintf('[r0:%d x %d x %d (%s)]', N, P, M, units(1,:));
    catch
        err     = 'Bad r0 structure';
    end
case '.r1'
    try
%        resp    = r.r1;
        [M]     = length(resp);     % number of repeats
        [N P]   = size(getfield(resp(1),'data'));
        [F]     = size(getfield(resp(1),'timing'),1);
        units   = getfield(resp(1),'y_unit');
        t_rate  = getfield(resp(1),'t_rate');
        str     = sprintf('[r1: %d x %d x %d (%s)]', N, P, M, units(1,:));
    catch
        err     = 'Bad r1 structure';
    end
otherwise
    err         = 'LoadResponseFile only reads .r0 and .r1 files';
end

if ~isempty(err)
    str = err;
end