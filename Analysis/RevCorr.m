function c = RevCorr(data, stim, samplerate, stimrate,...
    stimstart, datastart, window);
% runs reverse correlation on a data sample associated with a 1D stimulus
% (which should be white noise, as no correction is done in this method)
% out = RevCorr(data, stim, samplerate, stimrate, stimstart, datastart, window)
% data - response (sampled at samplerate) (Hz)
% stim - stimulus (sampled at stimrate) (Hz)
% stimstart - time offset of stimulus (clockvec)
% datastart - time offset of response (clockvec)
% window - the window, in ms, to return, with 0 = 0 delay
% note that negative delays precede the response
%
% if stimrate == samplerate, no binning is done
%
% $Id$

if samplerate < stimrate
    error('Stimulus rate must be <= Sample rate');
    return;
elseif samplerate > stimrate
    bin = samplerate / stimrate;
    data = bindata(data, bin);
end

offset = fix((datenum(stimstart) - datenum(datastart)) * stimrate); % positive numbers - late stim
if offset > 0
    data = data(offset:end);
elseif offset < 0
    stim = stim(-offset:end);
end

if nargin > 6
    int = 1000 / stimrate;
    window = fix(window(1)/int:window(2)/int);
    c = xxxcorr(stim, data, window);
else
    c = xxxcorr(stim, data);
end


%%%%%%%%%%%%%%%%%%%%%55
function c = xxxcorr(stim, resp, window)
% plots a quick crosscorrelation of the stimulus and response
stim = stim - mean(stim);
resp = resp - mean(resp);
c = xcorr(stim(1:length(resp)), resp,'coeff');
if nargin == 3
    o = length(resp);
    c = c(o + window);
end