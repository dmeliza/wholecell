function d = ImportTool(path)
%
% Imports data from various sources (currently just DAQ files)
%
% Copyright 2003 Dan Meliza
% $Id$
%

olddir = pwd;
if ~isempty(path),cd(path),end
pn = uigetdir;
cd(pn);

[d.data, d.time, d.abstime, d.info] = daq2mat('stack');

cd(olddir);