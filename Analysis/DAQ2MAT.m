function [out] = daq2mat(runmode, traceindices)
% [d.data,d.time,d.abstime,d.info] =  daq2mat(mode,[traceindices])

% reads in all the daq files in a directory, sorts them by creation time, and
% outputs a mat file containing the following variables:

% mode: 'stack': arranges traces vertically
% data - MxNxP array of traces; traces arranged columnwise; P > 1 if multiple traces are kept
% time - Mx1 array of times corresponding to rows in data
% abstime = 1XN array of time offsets corresponding to the start of each trace (sec)
% info - a structure array of interesting property values (not implemented yet)
%

% mode: 'cat': concatenates traces horizontally
% data - MxN array, where M is the sum of the number of samples in the inputs
% time - Mx1 array, containing times.  No abstime correction is made
% abstime - clock vector giving the start time of the first trace
% info - nice info about acquisition
% data are sorted by relative abstime

% mode: 'indiv': applies gain and mode settings to individual traces

% $Id$

error(nargchk(1,2,nargin));

d = dir('*.daq');
if length(d) == 0
    error('No .daq files in current directory.');
end
names = {d.name};
% load info from the first file and figure out what to do with subsequent files
d = daqread(names{1},'info');
c = d.ObjInfo.Channel;
if length(c) > 1
    cnames = {c.ChannelName};
    amp = c(strmatch('amplifier',cnames));
    mode = c(strmatch('mode',cnames));
    gain = c(strmatch('gain',cnames));
else
    amp = c;
    mode = [];
    gain = [];
end
info.t_unit = 's';
info.t_rate = d.ObjInfo.SampleRate;
info.start_time = d.ObjInfo.InitialTriggerTime;
info.samples = d.ObjInfo.SamplesAcquired;
if ~isempty(gain)
    gain = gain.Index;
end
if ~isempty(mode)
    mode = mode.Index;
end
if nargin < 2
    traceindices = amp.Index;
end

switch lower(runmode)
case 'stack'
    
    data = single(zeros(info.samples,length(names),length(traceindices)));
    abstime = zeros(length(names),6);
    time = [];
    for i = 1:length(names);
        fn = names{i};
        if (exist(fn) > 0)
            [dat, t, at] = daqread(fn);
            if ~isempty(amp)
                j = amp.Index;
                [dat(:,j), units] = ReadDAQScaled(dat, j, gain, mode, amp.Units);
            end
            s = sprintf('%s: %d x %d (%s)',fn, length(t), length(traceindices), units);
            disp(s);
            if length(t) < length(time) | length(t) < 100
                disp('Data file too short');
            else
                time = t;
                data(:,i,:) = single(dat(:,traceindices));
                abstime(i,:) = at;
            end
        end
    end
    [abstime, ind] = reltimes(abstime);
    info.y_unit = units;
    data = data(:,ind,:);
    time = single(time);
    save('daqdata.mat','data','time','abstime','info');
    out.data = data;
    out.time = time;
    out.abstime = abstime;
    out.info = info;
    disp('Wrote data to daqdata.mat');

case 'cat'
    data = cell(1,length(names));
    abstime = zeros(length(names),6);
    time = cell(1,length(names));
    for i = 1:length(names);
        fn = names{i};
        if (exist(fn) > 0)
            [dat, t, at] = daqread(fn);
            if ~isempty(amp)
                j = amp.Index;
                [dat(:,j), units] = ReadDAQScaled(dat, j, gain, mode, amp.Units);
            end
            s = sprintf('%s: %d x %d (%s)',fn, length(t), length(traceindices), units);
            disp(s);
            time{i} = t;
            data{i} = single(dat(:,traceindices));
            abstime(i,:) = at;
        end
    end
    clocks = datenum(abstime);
    [at, ind] = sort(clocks);
    info.y_unit = units;
    data = cat(1,data{ind});
    disp('Aligning times');
    t = [];
    step = 0;
    for i = 1:length(ind)
        tm = time{ind(i)};
        t = cat(1,t,tm + step);
        step = t(end) + t(2) - t(1);
    end
    time = single(t);
    abstime = abstime(1,:);
    save('daqdata-cat.mat','data','time','abstime','info');
    out.data = data;
    out.time = time;
    out.abstime = abstime;
    out.info = info;
    disp('Wrote data to daqdata-cat.mat');
    
case 'indiv'
    for i = 1:length(names);
        fn = names{i};
        if (exist(fn) > 0)
            [dat, t, at] = daqread(fn);
            if ~isempty(amp)
                j = amp.Index;
                [dat(:,j), units] = ReadDAQScaled(dat, j, gain, mode, amp.Units);
            end
            s = sprintf('%s: %d x %d (%s)',fn, l(i), length(traceindices), units);
            disp(s);
            info.y_unit = units;
            data = single(dat(:,tracindices));
            time = single(t);
            abstime = at;
            [pn bn ext] = fileparts(fn);
            save([bn '.mat'],'data','time','abstime','info');
        end
    end
    
otherwise
    disp([runmode ' not supported.']);
    
end

function [abstime, ind] = reltimes(abstime)
% fixes the abstime vector to relative timings
clocks = datenum(abstime);
[at, ind] = sort(clocks);
info.starttime = at(1);
atv = datevec(at - at(1));
abstime = atv(:,4)*60 + atv(:,5) + atv(:,6)/60;
abstime = abstime';