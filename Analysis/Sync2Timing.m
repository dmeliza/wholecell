function [timing, avg] = Sync2Timing(sync)
%
% Converts a sync signal into a vector of indices that give the
% timing of the sync signal.  Designed for the signal from a
% photocell or some such that changes state every time the frame
% flips.  Assumes that the sync signal itself is synchronized such
% that the first point in the signal represents the initial ON (or OFF)
% transition.
%
% Known to have issues with heavily downsampled data, especially if
% if there is "ringing" between the sample rate and the frame rate.
% In these cases it's better to determine the timing from the original sync
% signal and use those offsets to bin the data.
%
% $Id$
sq = zeros(size(sync));
on = find(sync > sync(1));
sq(on) = 1;                     % square wave representing on and off states
timing = find(diff(sq));        % timing of transitions between on and off
avg = mean(diff(timing));       % the average frame rate