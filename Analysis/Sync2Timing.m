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
% In addition, because the photocell signal is not a square wave (often has
% a toe on the OFF transition because of residual phosphor glow or whatever)
% the timing can wind up alternating between two different values.  The current
% solution is to only use the ON transitions and interpolate the OFF values,
% though this is only a satisfactory solution if we're not trying to account
% for dropped frames.
%
% With the current setup, using a sync value of 1 volt and a simple photovoltaiccell
% hooked directly to the DAQ, there is a lag of about 6 ms between the appearance of
% the first frame and the 0 time point.
%
% $Id$
[r c] = size(sync);
% sq    = zeros([r c]);
% on    = find(sync > sync(1));
% sq(on) = 1;                     % square wave representing on and off states
% timing = find(diff(sq)>0);      % timing of transitions between on and off
% timing = interp(timing,2);      % interpolate OFF/ON transition times
% timing = timing(timing<=r);     % remove bad values
% avg = mean(diff(timing));       % the average frame rate
d       = max(sync) - sync(1);
ON      = sync > sync(1);         % rising phase of this signal is "appearance" of frame
OFF     = sync < min(sync) + d;   % rising phase of this signal is "appearance" of next frame
click   = diff(ON) > 0 | diff(OFF) > 0;
timing  = find(click);

function Y = interp(X, rate)
% linear interpolator, uses midpoint between supplied values (ignore rate)
d       = [diff(X)];
d       = [d;mean(d)] / 2;      % extrapolate last value
Y       = repmat(X,1,2);
Y(:,2)  = d + Y(:,1);
Y       = reshape(Y',prod(size(Y)),1);
Y       = round(Y);      