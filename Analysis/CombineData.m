function [data, time, err, count, Y] = CombineData(d, t, binsize, mode)
%
% [d, t, stdev, count] = CombineData(data, time, binsize)
% [output] = CombineData(data,time,binsize,'string') - generates a string array
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
Y = sparse(ceil(maxt/bs),len);
%% iterate through the data
while i <= maxt
    [X{n,1}] = deal(i);
    [X{n,2}] = deal([]);
    for j = 1:len
        tt = abs(t{j});
        ind = find(tt >= i & tt < (i+bs));
        dat = d{j}(ind);
        X{n,2} = cat(2,X{n,2},dat);
        if ~isempty(dat)
            Y(n,j) = mean(dat);
        end
    end
    i = i + bs;
    n = n+1;
end
%% iterate again to generate the final datasets
if nargin == 3
    len = size(X,1);
    [time,data,err,count] = deal([]);
    for n = 1:len
        len = length(time);
        if ~isempty(X{n,2})
            time(len+1) = X{n,1};
            data(len+1) = mean(X{n,2});
            err(len+1) = std(X{n,2});
            count(len+1) = length(X{n,2});
        end
    end
    time = time * sign(binsize);
end

