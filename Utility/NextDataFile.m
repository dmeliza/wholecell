function out = NextDataFile()
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

d = datevec(now);
out = sprintf('%s\\%s_%i_%i_%i_%i-%i-%02.0f',wc.control.data_dir,wc.control.data_prefix, d(:));
%out = sprintf('%s\\%s_%i_%i_%i',wc.control.data_dir,wc.control.data_prefix, d(1:3));
