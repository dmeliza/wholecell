function [out] = daq2r1(files, respchannel, syncchannel)

% DAQ2R1: Reads in a list of daq files and generates an r1 structure
% (this function supercedes the DAQ2MAT('indiv') function
%
% Usage: r1 = daq2r1(files,respchannel,syncchannel)
%
% files        - cell array of file names to be read in
% respchannel  - index of the channel defining the "response" (can be a vector, but not impl)
% syncchannel  - index of the sync channel (used to generate r1.timing)
%
% r1           - output structure
%
% See Also:     headers/r1_struct.m
%
% $Id$

error(nargchk(3,3,nargin));

out = r1_struct;
if isa(files,'char')
    files = {files};
end

for i = 1:length(files);
    fn = files{i};
    if (exist(fn) > 0)
        info         = GetDAQHeader(fn);
        [dat, time, abstime, units] = ReadDAQScaled(fn, info);
        dat          = daqread(fn);
        [N M]         = size(dat);
        fprintf('%s: %d x %d (%s)\n',fn, N, 1, units{1});
        out(i).data   = single(dat(:,respchannel));
        out(i).y_unit = units;
        out(i).timing = Sync2Timing(dat(:,syncchannel));
        out(i).t_rate = info.t_rate;
        out(i).info = info;
    end
end