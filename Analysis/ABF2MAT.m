function [data,time,abstime,info] = abf2mat(filename, ADC, episodeInterval)
% reads in an abf file and
% outputs a mat file containing the following variables:
% data - MxN array of traces; traces arranged columnwise
% time - Mx1 array of times corresponding to rows in data
% abstime = 1XN array of time offsets corresponding to the start of each trace (sec)
% info - a structure array of interesting property values
%
% [data,time,abstime,info] =  abf2mat(filename)
%
% $Id$
%kludge = 6142;

if (isstr(filename))
    fid = fopen(filename,'r','l');
    if (fid < 0)
        error('Unable to open file.');
    end
else
    fid = filename;
end

pc8h = getpc8header(fid);

% figure out some things from the header
pc8h.fGain = pc8h.fInstrumentScaleFactor.*pc8h.fADCProgrammableGain.*pc8h.fSignalGain;
gain = pc8h.fADCRange / pc8h.lADCResolution / pc8h.fGain(ADC);
offset = pc8h.fSignalOffset(ADC);
episodes = pc8h.lActualEpisodes;
sampleLength = pc8h.lActualAcqLength / episodes;

info.samples = sampleLength;
info.y_unit = char(pc8h.sADCUnits(1:2)');
info.t_unit = 's';
info.t_rate = 1000000/pc8h.fADCSampleInterval;
disp(sprintf('File %s contains %i samples at %i /s', filename ,info.samples, info.t_rate));
disp(sprintf('Units are in %s', info.y_unit));

% read data
data = zeros(sampleLength, episodes);
kludge = pc8h.lDataSectionPtr * 512;
fseek(fid, kludge, 'bof');
for i=1:episodes
    d = fread(fid, sampleLength, 'short') * gain + offset;
    if length(d) > sampleLength
        data(:,i) = d(1:sampleLength);
    elseif length(d) < sampleLength
        % do nothing
    else
        data(:,i) = d;
    end
end

% generate a time vector
interval = pc8h.fADCSampleInterval/1000000;
time = 0:interval:(sampleLength-1)*interval;

% abstime also has to be kludged because there's no way (that I can tell)
% to get the time between episodes out of the abf file
abstime = 0:episodeInterval:episodeInterval*(episodes -1);

[path basename] = fileparts(filename);
fn = [basename '.mat'];
save(fn, 'data','time','abstime','info');
disp(['Wrote data to ' fn]);

