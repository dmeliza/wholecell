function [data,time,abstime,info] = daq2mat(varargin)
% reads in all the daq files in a directory, sorts them by creation time, and
% outputs a mat file containing the following variables:
% data - MxN array of traces; traces arranged columnwise
% time - Mx1 array of times corresponding to rows in data
% abstime = 1XN array of time offsets corresponding to the start of each trace (sec)
% info - a structure array of interesting property values (not implemented yet)
%
% [data,time,abstime,info] =  daq2mat([directory])
% [data,time,abstime,info] =  daq2mat({directories})
% $Id$

oldpn = pwd;
if (nargin > 0)
    pn = varargin{1};
    if (iscell(pn))
        for i=1:length(pn)
            daq2mat(pn{i});
        end
    else
        cd(varargin{1});
    end
end

d = dir('*.daq');
if length(d) == 0
    return
end
names = {d.name};

% load info from the first file and figure out what to do with subsequent files
d = daqread(names{1},'info');
c = d.ObjInfo.Channel;
if length(c) > 1
    cnames = {c.ChannelName};
    output = c(strmatch('amplifier',cnames));
    mode = c(strmatch('mode',cnames));
    gain = c(strmatch('gain',cnames));
else
    output = c;
    mode = [];
    gain = [];
end
if isempty(mode)
    info.y_unit = c.Units;
else
    m = daqread(names{1},'Channel',mode.Index);
    info.y_unit = TelegraphReader('units',mean(m));
end
info.t_unit = 's';
info.t_rate = d.ObjInfo.SampleRate;
info.samples = d.ObjInfo.SamplesAcquired;
disp(sprintf('File %s contains %i samples at %i /s', names{1} ,info.samples, info.t_rate));
disp(sprintf('Units are in %s', info.y_unit));

data = zeros(info.samples,length(names));
abstime = zeros(length(names),6);
time = [];
for i = 1:length(names);
    fn = names{i};
    if (exist(fn) > 0)
        if isempty(gain)
            [dat, t, at] = daqread(fn,'Channel',output.Index);
        else
            [dat, t, at] = ReadDAQScaled(fn,output.Index, gain.Index, info.y_unit);
        end
        if (length(t) < length(time))
            % corrupted file
            disp(['Data file ' fn ' too short; ignored.']);
%         elseif length(t) > length(time)
%             % this usually happens if the first file is corrupted
%             % in which case we rezero out the data and basically start over
%             disp('corrupted data file')
%             data = zeros(length(t), length(names));
        else
            time = t;
            data(:,i) = dat;
            abstime(i,:) = at;
            disp(['Loaded ' num2str(length(time)) ' samples from ' fn]);
        end
    end
end

% now we have three arrays. rows in abstime correspond to columns
% in data and time.  The first task is to convert the cell arrays
% into matrices by finding the shortest episode [taken care of w/ daqread]
% then we sort the rows in abstime, and use the sorting indices to reorder
% data.
clocks = datenum(abstime);
[at, ind] = sort(clocks);
info.starttime = at(1);
atv = datevec(at - at(1));
abstime = atv(:,4)*60 + atv(:,5) + atv(:,6)/60;
abstime = abstime';
data = data(:,ind);
save('daqdata.mat','data','time','abstime','info');
disp('Wrote data to daqdata.mat');
cd(oldpn);

