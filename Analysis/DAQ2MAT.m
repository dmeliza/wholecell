function [out] = daq2mat(runmode, channels)
% [d.data,d.time,d.abstime,d.info] =  daq2mat(mode,args)

% reads in all the daq files in a directory, sorts them by creation time, and
% outputs a file with the result.

% mode: 'stack': arranges traces vertically. short episodes are discarded
%                an r0 file is generated
%                args are the channels to keep

% mode: 'cat':   concatenates traces horizontally and generates an r0 file
%                data are sorted by relative abstime
%                args are respchannel

% mode: 'indiv': applies gain and mode settings to individual traces, generating a
%                structure array as an output (r1 file)
%                args are respchannel,synchannel
%
% 1.13: NOTE: DAQ2MAT NO LONGER WRITES ANYTHING TO THE DISK
% 1.14: DAQ2MAT is becoming a wrapper for DAQ2R0 and DAQ2R1, and it will
%      write to disk

% $Id$

error(nargchk(1,2,nargin));

d = dir('*.daq');
if length(d) == 0
    error('No .daq files in current directory.');
end
names = {d.name};

% load info from the first file and figure out what to do with subsequent files
info = getdaqheader(names{1});
if nargin < 2
    traceindices = info.amp;
end
amp = info.channels(info.amp);


switch lower(runmode)
case 'stack'
    
    out = DAQ2R0(names,channels);

case 'cat'
    data = cell(1,length(names));
    abstime = zeros(length(names),6);
    time = cell(1,length(names));
    for i = 1:length(names);
        fn = names{i};
        if (exist(fn) > 0)
            [dat, t, at] = daqread(fn);
            if ~isempty(info.gain)
                j = info.amp;
                [dat(:,j), units] = ReadDAQScaled(dat, j, info.gain, info.mode, amp.Units);
            end
            fprintf('%s: %d x %d (%s)\n',fn, length(t), length(traceindices), units);
            time{i} = t;
            data{i} = single(dat(:,traceindices));
            abstime(i,:) = at;
        end
    end
    clocks = datenum(abstime);
    [at, ind] = sort(clocks);
    info.y_unit = units;
    out.data = cat(1,data{ind});
    disp('Aligning times');
    t = [];
    step = 0;
    for i = 1:length(ind)
        tm = time{ind(i)};
        t = cat(1,t,tm + step);
        step = t(end) + t(2) - t(1);
    end
    out.time = single(t);
    abstime = abstime(1,:);
    out.abstime = abstime;
    out.info = info;
    
case 'indiv'
    
    out = DAQ2R1(names, channels(1), channels(2));
    
otherwise
    disp([runmode ' not supported.']);
    
end