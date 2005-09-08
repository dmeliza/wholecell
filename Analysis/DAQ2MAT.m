function [out] = daq2mat(runmode, channels)
% [d.data,d.time,d.abstime,d.info] =  daq2mat(mode,args)
%
% reads in all the daq files in a directory, sorts them by creation time, and
% outputs a file with the result.
%
% mode: 'stack': arranges traces vertically. short episodes are discarded
%                an r0 file is generated
%                args are the channels to keep
%
% mode: 'cat':   concatenates traces horizontally and generates an r0 file
%                data are sorted by relative abstime
%                args are respchannel
%
% mode: 'indiv': applies gain and mode settings to individual traces, generating a
%                structure array as an output (r1 file)
%                args are respchannel,synchannel
%
% 1.13: NOTE: DAQ2MAT NO LONGER WRITES ANYTHING TO THE DISK
% 1.14: DAQ2MAT is becoming a wrapper for DAQ2R0 and DAQ2R1, and it will
%      write to disk
% 1.17: If a sequence.txt file is present, the responses to each stimulus type are
%       aggregated into separate r0 files.

% $Id$

error(nargchk(1,2,nargin));

d = dir('*.daq');
if length(d) == 0
    error('No .daq files in current directory.');
end
names = {d.name};

% load info from the first file and figure out what to do with subsequent files
info = GetDAQHeader(names{1});
if nargin < 2
    traceindices = info.amp;
end
amp = info.channels(info.amp);


switch lower(runmode)
case 'stack'
    
    if exist('sequence.txt','file')
        seq     = load('-ascii','sequence.txt');
        uni     = unique(seq);
        for i = 1:length(uni)
            ind = find(seq==uni(i));
            ind = ind(ind<=length(names));
            n  = names(ind);
            r0 = DAQ2R0(n, channels);
            save(sprintf('daqdata-%d.r0',uni(i)),'r0','-mat');
        end
    else
        r0 = DAQ2R0(names,channels);
        save('daqdata.r0','r0','-mat');
    end
    out = r0;

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
    
    r1 = DAQ2R1(names, channels(1), channels(2));
    save('daqdata.r1','r1','-mat');
    out = r1;
    
otherwise
    disp([runmode ' not supported.']);
    
end