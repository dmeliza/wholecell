function [resp, str] = CombineFiles(type,filenames,channels)
%
% This function is used to concatenate multiple files into a single .r1 or .r0
% file.  It uses LoadResponseFile to load the .r1 or .r0 files, and DAQ2R0 and DAQ2R1
% to load the .daq files. r1 files cannot be converted to .r0 files or vice versa.
%
% Usage: [resp, str] = CombineFiles(type,filenames,<channels>)
%
% type      - 'r1' or 'r0' (error if filenames contains files of the other type)
% filenames - filenames of responses (cell array or string matrix)
% channels  - the channels to be included (required if there are .daq files)
% 
% resp     - the response structure (empty in errors)
% str      - a string describing the response properties (or the error)
%
% See Also:     headers/r0_struct.m
%               headers/r1_struct.m
%
% $Id$

error(nargchk(2,3,nargin));
resp = {};
err = [];

if isa(filenames,'char')
    filenames = deblank(cellstr(filenames));
end

% Sort filenames into types
for i = 1:length(filenames)
    [pn fn ext{i}] = fileparts(filenames{i});
end
[ext, i, j] = unique(ext);

% Check for illegal conversions
if strcmpi(type,'r1') & ~isempty(strmatch('.r0',ext))
    error('r0 files cannot be converted to r1');
elseif strcmpi(type,'r0') & ~isempty(strmatch('.r1',ext))
    error('r1 files cannot be converted to r0');
end

% treat each filetype
for i = 1:length(ext)
    ind   = find(j==i);
    files = {filenames{ind}};
    switch lower(ext{i})
    case '.daq'
        if nargin < 3
            error('Channel argument must be supplied to convert .daq files');
        end
        switch lower(type)
        case 'r0'
            resp{length(resp)+1} = DAQ2R0(files, channels);
        case 'r1'
            if length(channels) < 2
                error('R1 files require two channels (signal and sync)');
            end
            resp{length(resp)+1} = DAQ2R1(files, channels(1), channels(2));
        otherwise
            error('Output type must be ''r1'' or ''r0''!');
        end
    case {'.r1','.r0'}
        for j = 1:length(files)
            [resp{length(resp)+1} str] = LoadResponseFile(files{j});
            fprintf('%s: %s\n', files{j},str);
        end
    otherwise
        fprintf('%s files ignored...\n', ext{i});
    end
end

% concatenate into final product
switch lower(type)
case 'r0'               % abstime is appended, and data is catted, if dimensions are correct
    out = resp{1};
    for i = 2:length(resp)
        [N M P] = size(out.data);
        [I J K] = size(resp{i}.data);
        if I==N & P==K
            out.data    = cat(2,out.data,resp{i}.data);
            out.abstime = cat(2,out.abstime,resp{i}.abstime);
        else
            warning(['Dimension mismatch item ' num2str(i)]);
        end
    end
    resp = out;
    [N M P] = size(resp.data);
    str  = sprintf('[r0: %d x %d x %d (%s)', N, P, M, resp.y_unit);
case 'r1'               
    resp = [resp{:}];   % structure arrays are appended to each other, no checks
    [N P]= size(resp(1).data);
    str  = sprintf('[r1: %d x %d x %d (%s)]', N, P, length(resp), resp(1).y_unit);
end