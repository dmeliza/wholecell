function out = NextDataFile(varargin)
% Determines a name for the next file to store data in
% out = NextDataFile()
% returns a string, sans extension that can be given to a daq for LogFileName
% or whatever.
%
% the filename returned will look like
% {path}\{prefix}year_month_day
%
% $Id$
global wc

if nargin == 0
    d = datevec(now);
    %out = sprintf('%s\\%s_%i_%i_%i_%i-%i-%02.0f',wc.control.data_dir,wc.control.data_prefix, d(:));
    files = dir(wc.control.data_dir);
    n = {files.name};
    basename = sprintf('%s_%i_%i_%i-',wc.control.data_prefix, d(1:3));
    files = strmatch(basename,n);
    if isempty(files)
        out = sprintf('%s%s%s000',wc.control.data_dir,filesep,basename);
    else
        files = sort(n(files));
        lastfile = files{length(files)};
        out = NextDataFile([wc.control.data_dir filesep lastfile]);
    end
else
    lastname = varargin{1};
    [path name ext] = fileparts(lastname);
    len = length(name);
    index = str2num(name(len-2:len));
    newname = sprintf('%s%03.0f.daq',name(1:len-3),index+1);
    out = fullfile(path, newname);
end
    