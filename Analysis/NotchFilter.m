function out = NotchFilter(data, notch, Fs, order)
%
% Applies a very simple notch filter to a dataset.   The data is tranformed
% to Fourier space and the fundamental and overtones of the notch frequency
% are eliminated. Only works with a single notch frequency; for bandstop
% filters a simple butterworth is better.  Operates down columns of matrix
% data.
%
% out = NOTCHFILTER(data, notch, Fs, [order])
%
% The default order is 6
%
% $Id$
if nargin < 4
    OVERTONES   = 6;
else
    OVERTONES   = order;
end

X       = fft(data);
% 60 Hz will be at f * n / Fs + 1, where f is multiples of 60 (not worth
% doing much more than 2-5 overtones since we'll lowpass this later. We
% also have to get the negative frequencies.
n       = size(data,1);
f       = notch * [1:OVERTONES];
k       = round(f .* n ./ Fs);
k       = [k + 1, n - k + 1];
% interpolate with nearest neighbors
k_plus  = X(k+1,:);
k_minus = X(k-1,:);
X(k,:)  = mean(cat(3,k_plus,k_minus),3);
% return to normal space
out     = real(ifft(X));
