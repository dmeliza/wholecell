function out = GetDirectory(directory, filter, option)
%
% Returns a nicely sorted cell array containing the names of files and directories
% in a directory.
%
% Usage:  GetDirectory(path, filter, option)
%
% path   - the directory to examine
% filter - wildcard specifications of which kinds of files to include. Can be a cell
%          array of multiple filters
% option - can be 'dirs', in which case directories will be included (with trailing /)
%
% out    - sorted cell array, with directories at the top
%
% $Id$

error(nargchk(2,3,nargin))
if nargin < 3
    option = 'nodirs';
end

olddir  = pwd;
cd(directory);

if isa(filter,'char')
    filter = cellstr(filter);
    out = dirlist(filter{:});
elseif isa(filter,'cell')
    out = dirlist(filter{:});
else
    error('filter must be a cell or character array');
end

% sorty
out = sort(out);

% dirs
if strcmpi(option,'dirs')
    d   = directories;
    out = {d{:}, out{:}};
end

function out = dirlist(varargin)
% cycles through the joyous parameters and determines which lovely files
% with those filter specifications belong in the wondrous output
out = {};
for i=1:nargin
    filter = varargin{i};
    d      = dir(filter);
    name   = {d.name};
    out    = {out{:},name{:}};
end

function out = directories()
% generates a scrumptious cell array listing the directories, with
% absolutely necessary trailing slashes
d   = dir;
i   = find([d.isdir]);
out = {d(i).name};
for i = 1:length(out)
    st = out{i};
    out{i} = [st '/'];
end