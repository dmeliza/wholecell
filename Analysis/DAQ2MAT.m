function [out] = daq2mat(runmode, traceindices)
% [d.data,d.time,d.abstime,d.info] =  daq2mat(mode,[traceindices])

% reads in all the daq files in a directory, sorts them by creation time, and
% outputs a mat file containing the following variables:

% mode: 'stack': arranges traces vertically. short episodes are discarded
% data - MxNxP array of traces; traces arranged columnwise; P > 1 if multiple traces are kept
% time - Mx1 array of times corresponding to rows in data
% abstime = 1XN array of time offsets corresponding to the start of each trace (sec)
% info - a structure array of interesting property values
%

% mode: 'cat': concatenates traces horizontally
% data - MxN array, where M is the sum of the number of samples in the inputs
% time - Mx1 array, containing times.  No abstime correction is made
% abstime - clock vector giving the start time of the first trace
% info - nice info about acquisition
% data are sorted by relative abstime

% mode: 'indiv': applies gain and mode settings to individual traces, generating a
%                structure array as an output
%
% 1.3: NOTE: DAQ2MAT NO LONGER WRITES ANYTHING TO THE DISK

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
    
    data = single(zeros(info.samples,length(names),length(traceindices)));
    abstime = zeros(length(names),6);
    time = [];
    for i = 1:length(names);
        fn = names{i};
        if (exist(fn) > 0)
            [dat, t, at] = daqread(fn);
            if ~isempty(info.gain)
                j = info.amp;
                [dat(:,j), units] = ReadDAQScaled(dat, j, info.gain, info.mode, amp.Units);
            end
            fprintf('%s: %d x %d (%s)\n',fn, length(t), length(traceindices), units);
            if length(t) < length(time) | length(t) < 100
                disp('Data file too short');
            else
                time = t;
                data(:,i,:) = single(dat(:,traceindices));
                abstime(i,:) = at;
            end
        end
    end
    [out.abstime, ind] = reltimes(abstime);
    info.y_unit = units;
    out.data = data(:,ind,:);
    out.time = single(time);
    out.info = info;

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
    for i = 1:length(names);
        fn = names{i};
        if (exist(fn) > 0)
            [dat, t, at] = daqread(fn);
            if ~isempty(info.gain)
                j = info.amp;
                [dat(:,j), units] = ReadDAQScaled(dat, j, info.gain, info.mode, amp.Units);
            end
            fprintf('%s: %d x %d (%s)\n',fn, length(t), length(traceindices), units);
            info.y_unit = units;
            out(i).data = single(dat(:,traceindices));
            out(i).time = single(t);
            out(i).abstime = at;
            out(i).info = info;
        end
    end
    
otherwise
    disp([runmode ' not supported.']);
    
end

function [abstime, ind] = reltimes(abstime)
% fixes the abstime vector to relative timings
clocks = datenum(abstime);
[at, ind] = sort(clocks);
% remove failed files by clipping out zeros
i = find(at);
at = at(i);
ind = ind(i);
% convert to relative times (minutes)
info.starttime = at(1);
atv = datevec(at - at(1));
abstime = atv(:,4)*60 + atv(:,5) + atv(:,6)/60;
abstime = abstime';