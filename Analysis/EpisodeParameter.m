function out = EpisodeParameter(param, ds)
%
% An internal function used to calculate the values of
% some measured parameter in an episodic acquisition (e.g. input resistance)
%
% Usage:
%
%       res = EpisodeParameter(paramstruct,r0)
%           - calculates the value of the parameter. r0 is a structure
%             that must contain the fields 'data' and 'time'
%
%
% $Id$
if nargin < 2
    disp('EpisodeParameter is started from EpisodeAnalysis')
    out = [];
    return
end
if strcmpi(param.action,'none')
    out = [];
    return
end

% cycle through all the various shit in the ds to produce the output
% structure array
ct  = 0;
for i = 1:length(ds)
    ind     = getIndices(param.marks, ds(i).time);
    dt      = mean(diff(double(ds(i).time)));
    chan    = ds(i).chan;
    for j = 1:length(chan)
        c   = chan(j);
        [res, units] = compute(param.action, double(ds(i).data(:,:,j)),...
                               ind, ds(i).units, dt);
        ct  = ct + 1;
        out(ct) = struct('fn',ds(i).fn,'channel',ds(i).channels{c},...
                         'start',ds(i).start,'units',units,'color',ds(i).color(c,:),...
                         'abstime',ds(i).abstime,'value',res);
    end
end
out = fixAbstime(out);


function [out, units] = compute(action, data, ind, units, dt)
% Makes the calculations
out = [];
switch lower(action)
case 'none'
    return
case {'amplitude','difference','slope'}
    % absolute value of the amplitude difference between two marks
    % if three marks, baseline is mean of values between first two
    % if four marks, 2nd value is mean of values between 2nd two
    switch length(ind)
    case 4
        bs  = mean(data(ind(1:2),:),1);
        vl  = mean(data(ind(3:4),:),1);
        out = (vl - bs);
        dt  = dt * (ind(3) - ind(2));
    case 3
        bs  = mean(data(ind(1:2),:),1);
        out = (data(ind(3),:) - bs);
        dt  = dt * (ind(3) - ind(2));
    case 2
        out = (diff(data(ind,:)));
        dt  = dt * (ind(2) - ind(1));
    end
    switch lower(action)
    case 'amplitude'
        out = abs(out);
    case 'slope'
        out     = out / dt / 1000;
        units   = sprintf('%s/%s',units,'ms');
    end
end

function res = fixAbstime(res)
% converts abstime data to relative start-times
start   = datenum(cat(1,res.start));
offset  = datevec(start - min(start));
offmins = offset(:,4) * 60 + offset(:,5) + offset(:,6) / 60;
for i = 1:length(res)
    res(i).abstime = res(i).abstime + offmins(i);
end

function ind = getIndices(times, time)
% converts time offsets into indices into the time vector
% where the time offset falls between two sample times, the lower value is chosen
for i = 1:length(times)
    TI      = find(time >= times(i));
    ind(i)  = TI(1);
end
