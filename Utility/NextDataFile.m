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
    out = sprintf('%s%s_%i_%i_%i-000',wc.control.data_dir,wc.control.data_prefix, d(1:3));
else
    lastname = varargin{1};
    len = length(lastname);
    index = str2num(lastname(len-6:len-3));
    out = sprintf('%s%03.0f.daq',lastname(1:len-7),index + 1);
end
    