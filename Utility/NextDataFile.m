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

if nargin == 0
    pf = GetUIParam('protocolcontrol','data_prefix','String');
    dd = GetUIParam('protocolcontrol','data_dir','String');
    d = datevec(now);
    %out = sprintf('%s\\%s_%i_%i_%i_%i-%i-%02.0f',wc.control.data_dir,wc.control.data_prefix, d(:));
    files = dir(dd);
    n = {files.name};
    if isempty(pf)
        pf = 'wc';
        SetUIParam('protocolcontrol','data_prefix','String',pf);
    end
    basename = sprintf('%s_%i_%i_%i-',pf, d(1:3));
    files = strmatch(basename,n);
    if isempty(files)
        out = sprintf('%s%s%s000',dd,filesep,basename);
    else
        files = sort(n(files));
        lastfile = files{length(files)};
        out = NextDataFile([dd filesep lastfile]);
    end
else
    lastname = varargin{1};
    [path name ext] = fileparts(lastname);
    len = length(name);
    index = str2num(name(len-2:len));
    newname = sprintf('%s%03.0f.daq',name(1:len-3),index+1);
    out = fullfile(path, newname);
end
    