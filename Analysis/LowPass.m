function d = LowPass(data, lpass, Fs)
% Filters data using a 3-pole butterworth lowpass filter.
% Uses FiltFilt to avoid phase offsets.
% d = LowPass(data, lpass(Hz), Fs(Hz))
% undefined results if lpass > Fs
%[b, a] = butter(6,lpass/Fs);
[b,a] = ellip(3,0.5,20,lpass/Fs);
d = filtfilt(b,a,data);