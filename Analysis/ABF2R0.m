function r0 = abf2r0(filename, episodeInterval, channels)
% ABF2R0: reads in an Axon Binary File and returns the values in a format
% usable by matlab:
%
% r0 =  abf2r0(filename, episodeInterval, [channels])
%
% An ABF file can contain multiple episodes and multiple channels, so the
% array returned has the dimensions SAMPLESxEPISODESxCHANNELS.  The data is
% returned in an r0 structure (see headers/r0_struct.m)
%
%
% Copyright C. Daniel Meliza 2002-2005
% Free for use under a Creative Commons Attribution Licence
% (http://creativecommons.org/licenses/by/2.0/)
%
% $Id$

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
ds      = pc8h.lFileStartDate;
yr      = fix(ds/1e4);
mo      = fix(ds/1e2) - yr*1e2;
dy      = ds - mo*1e2 - yr*1e4;
start_time  = datevec(datenum(yr,mo,dy,0,0,pc8h.lFileStartTime));
pc8h.fGain  = pc8h.fInstrumentScaleFactor.*pc8h.fADCProgrammableGain.*pc8h.fSignalGain;
nchannels   = pc8h.nADCNumChannels;
gain        = pc8h.fADCRange / pc8h.lADCResolution ./ pc8h.fGain(1:nchannels);
offset      = pc8h.fSignalOffset(1:nchannels);
episodes    = pc8h.lActualEpisodes;
sampleLength = pc8h.lActualAcqLength / episodes;

if nargin < 3
    channels    = 1:nchannels;
elseif any(channels > nchannels)
    error(sprintf('ABF file only has %d channels', nchannels));
end

% if multiple channels are recorded, the values are interleaved with each
% other, which sounds like a great idea but isn't terribly convenient to
% deal with...
samples = sampleLength / nchannels;
t_unit = 's';
for i = 1:nchannels
    arr_offset  = (i - 1) * 8;
    y_unit{i} = char(pc8h.sADCUnits(arr_offset+1:arr_offset+8)');
end
t_rate = 1000000/pc8h.fADCSampleInterval / nchannels;
fprintf('File %s contains %i channels with %i samples at %i /s\n',...
    filename, nchannels, samples, t_rate);

% read data from the file
data = zeros([samples, episodes, length(channels)]);
kludge = pc8h.lDataSectionPtr * 512;
fseek(fid, kludge, 'bof');
for i=1:episodes
    d = fread(fid, sampleLength, 'short');
    % check for too long of an episode (very unlikely)
    if length(d) > sampleLength
        d   = d(1:sampleLength);
    elseif length(d) < sampleLength
        % do nothing
    end
    % reshape the data for multiple channels
    d   = reshape(d,[nchannels,1,samples]);
    data(:,i,:) = permute(d(channels,:,:),[3 2 1]);
end
% apply gain and offset data, which are independent for each channel:
data   = data .* repmat(shiftdim(gain(channels),-2),[size(data,1),size(data,2),1])...
         - repmat(shiftdim(offset(channels),-2),[size(data,1),size(data,2),1]);

% generate a time vector based on the sampling rate
interval = 1 / t_rate;
time     = shiftdim(0:interval:(samples-1)*interval,1);

% abstime also has to be kludged because there's no way (that I can tell)
% to get the time between episodes out of the abf file
abstime = 0:episodeInterval:episodeInterval*(episodes -1);

% package up output structure
r0  = struct('data',data,'time',time,'abstime',abstime,...
    't_rate', t_rate,...
    'y_unit', char(y_unit),...
    'start_time', start_time,...
    'info',pc8h,...
    'channels',channels);
