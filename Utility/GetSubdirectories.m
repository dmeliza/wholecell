function out = GetSubdirectories(filter)
%
%  subdirs = GetSubdirectories([filter])
%
% Returns a cell array containing all the subdirectories (i.e. excluding
% '.' and '..') of the directory specified in the filter (default is the
% current directory);
%
% $Id$

error(nargchk(0,1,nargin))
if nargin==0
    filter = '.';
end

d       = dir(filter);
out     = {d.name};
sel     = find([d.isdir]);
reject  = strmatch('.',out);
sel     = setdiff(sel,reject);
out = out(sel);

