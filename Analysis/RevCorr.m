function c = RevCorr(data, stim, samplerate, stimrate,...
    stimstart, datastart, window);
% runs reverse correlation on a data sample associated with a 1D stimulus
% (which should be white noise, as no correction is done in this method)
% out = xcorr(data, stim, samplerate, stimrate, stimstart, datastart, window)
% data - response (sampled at samplerate)
% stim - stimulus (sampled at stimrate)
% stimstart - time offset of stimulus
% datastart - time offset of response
% window - the window, in ms, to return, with 0 = 0 delay
% note that negative delays precede the response
%
% $Id$

bin = samplerate * stimrate / 1000;
d = bindata(data, bin);
offset = fix((datenum(stimstart) - datenum(datastart)) * 1000 / stimrate); % positive numbers - late stim
if offset > 0
    d = d(offset:end);
elseif offset < 0
    stim = stim(-offset:end);
end

window = fix(window(1)/stimrate:window(2)/stimrate);
c = xxxcorr(d, stim,window);


%%%%%%%%%%%%%%%%%%%%%55
function c = xxxcorr(stim, resp, window)
% plots a quick crosscorrelation of the stimulus and response
stim = stim - mean(stim);
resp = resp - mean(resp);
c = xcorr(resp, stim);
if nargin == 3
    o = length(c) / 2;
    c = c(o + window);
end