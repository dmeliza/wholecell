function varargout = daq2mat(varargin)
% reads in all the daq files in a directory, sorts them by creation time, and
% outputs a mat file containing the following variables:
% data - MxN array of traces; traces arranged columnwise
% time - Mx1 array of times corresponding to rows in data
% abstime = 1XN array of time offsets corresponding to the start of each trace (sec)
%
% void daq2mat([directory])
% void daq2mat({directories})
% $Id$
samples = [1 9000];

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
names = {d.name};

% first find out what the shortest episode is.  we have to do this to
% allow packing data into a matrix
data = [];
abstime = [];
for i = 1:length(names);
    fn = names{i};
    if (exist(fn) > 0)
        [dat, time, at] = daqread(fn,'Channels',1,'Samples',[1 9000]);
        if (length(time) < samples(2))
            disp(['Data file ' fn ' too short; ignored.']);
        else
            data = [data,dat];
            abstime = [abstime;at];
            disp(['Loaded trace from ' fn]);
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
atv = datevec(at - at(1));
abstime = atv(:,4)*60 + atv(:,5) + atv(:,6)/60;
abstime = abstime';
data = data(:,ind);
save('daqdata.mat','data','time','abstime');
disp('Wrote data to daqdata.mat');
cd(oldpn);