function data = HighPass(data, pass, Fs, order)
% Filters data using an n-pole butterworth highpass filter.
% Uses FiltFilt to avoid phase offsets.
% d = HighPass(data, pass(Hz), Fs(Hz), [order])
%
% data  - column array of input data (double)
% pass  - passband, in Hz
% Fs    - sampling rate of data, in Hz
% order - the order of the filter, default = 3
%
% undefined results if pass > Fs
%
% $Id$
error(nargchk(3,4,nargin))
if nargin < 4
    order   = 3;
end
Wn          = pass/(Fs/2);
[b,a]       = butter(order,Wn,'high');
data        = filtfilt(b,a,data);
