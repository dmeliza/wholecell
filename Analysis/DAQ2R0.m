function [out] = daq2r0(files, channels)

% DAQ2R0: Reads in a list of daq files and generates an r0 structure
% (this function supercedes the DAQ2MAT('stack') function)
%
% Usage: r0 = daq2r0(files, channels)
%
% files        - cell array of file names to be read in
% channels     - index of the channels to keep
%
% r0           - output structure
%
% See Also:     headers/r0_struct.m
%
% $Id$

error(nargchk(2,2,nargin));

out = r0_struct;
if isa(files,'char')
    files    = {files};
end

% first loop through the files to get sample lengths
% it's very rare for an episode to be too long, and common for it to be
% too short, so rather than look for the most common episode length
% we just pick the longest episodes
for i = 1:length(files)
    info(i)  = GetDAQHeader(files{i});
end
lengths      = [info.samples];  % episode lengths
[B,I,J]      = unique(lengths); % sort episode lengths
B            = B(1);            % number of samples in the longest episodes
ind          = find(J==1);      % indices of the longest episodes
  
% Initialize outputs
out.data     = single(zeros([B, length(ind), length(channels)]));
out.abstime  = zeros(length(ind),6);
out.time     = zeros([B 1]);

for i = ind
    fn                   = files{i};
    if exist(fn) > 0
        [dat, t, at]     = daqread(fn);
        j                = info(i).amp;
        units            = info(i).channels(j).Units;
        if ~isempty(info(i).gain)
            [dat(:,j), units] = ReadDAQScaled(dat, j, info(i).gain, info(i).mode, units);
        end
        fprintf('%s: %d x %d (%s)\n',fn, length(t), length(channels), units);
        out.data(:,i,:)  = single(dat(:,channels));
        out.abstime(i,:) = at;
    end
end
out.time        = single(t);
out.y_unit      = units;  %  this breaks the r0 spec if multiple channels are selected
[out.abstime,i] = reltimes(out.abstime);
out.t_rate      = info(1).t_rate;
out.data        = out.data(:,ind,:);
out.info        = info(1);
out.channels    = channels;

function [abstime, ind] = reltimes(abstime)
clocks    = datenum(abstime);                   % convert clock vectors to datenums
[at, ind] = sort(clocks);                       % sort abstimes, keeping indices
i         = find(at);                           % locate failed files (at = 0)
at        = at(i);
ind       = ind(i);
atv       = datevec(at - at(1));                  % convert to relative times
abstime   = atv(:,4)*60 + atv(:,5) + atv(:,6)/60; % minutes
abstime   = abstime';                             % column vector