function [data, time, err] = CombineData(d, t, binsize)
%
% [d, t, stdev] = CombineData(data, time, binsize)
% data - 1xM cell array containing 1xQ vectors (Q can vary)
% time - 1xM cell array containing 1xQ vectors (Q must correspond to data)
% binsize - size of final bins; should be negative if times are negative
% d,t - 1x(max(Q)) vectors
% err - 1x(max(Q)) vectors with standard deviation
% combines multiple datasets into a single averaged dataset with
% standard deviation between timepoints.  For instance, if you have
% the following datasets:
%
% [1 2 3 4 5], [2 3 5], [1.5]
% CombineData will give you [1.5 2.5 4 4 5]
% To account for the fact that different datasets have already been binned
% and at different timepoints, CombineData also re-bins the data into
% timebins of binsize (in whatever units time is in)
%
% Because matlab isn't good at handling different-sized data sets I've
% implemented this algorhythmically.
%
% Copyright Dan Meliza
% $Id$

%% some initial conditions
i = 0; % current lower bound of bin
n = 1; % number of the current bin
len = length(d);
X = {}; % 2xlen cell array, each row is (time,[data points])
bs = abs(binsize);
% find the longest time
for j = 1:len
    maxt(j) = max(abs(t{j}));
end
maxt = max(maxt);
%% iterate through the data
while i <= maxt
    X{n,1} = i;
    X{n,2} = [];
    for j = 1:len
        tt = abs(t{j});
        ind = find(tt >= i & tt < (i+bs));
        X{n,2} = cat(2,X{n,2},d{j}(ind));
    end
    i = i + bs;
    n = n+1;
end
%% iterate again to generate the final datasets
len = size(X,1);
[time,data,err] = deal([]);
for n = 1:len
    len = length(time);
    if ~isempty(X{n,2})
        time(len+1) = X{n,1};
        data(len+1) = mean(X{n,2});
        err(len+1) = std(X{n,2});
    end
end
if (binsize < 0)
    time = -time;
end
