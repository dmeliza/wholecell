function [data,time,abstime,info] = LoadEpisode(filepath)
% loads data from a .mat file, which should have the following
% variables stored:
% data - MxN array of traces; traces arranged columnwise
% time - Mx1 array of times corresponding to rows in data
% abstime = 1XN array of time offsets corresponding to the start of each trace (sec)
% info - a structure array of interesting property values (not implemented yet)
%
% [data,time,abstime,info] = LoadEpisode(matfile)
% returns 0 if something fails
%
% $Id$

[data,time,abstime,info] = deal(0);

if (exist(filepath,'file') ~= 2)
    return;
end

d = load(filepath);
if (isfield(d,'data'))
    data = d.data;
end
if (isfield(d,'time'))
    time = d.time;
end
if (isfield(d,'abstime'))
    abstime = d.abstime;
end
if (isfield(d,'info'))
    info = d.info;
end
