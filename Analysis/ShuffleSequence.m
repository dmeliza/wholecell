function out = ShuffleSequence(data, chunks)
%
% Divides a vector in several chunks and shuffles those around
%
% USAGE:    out = ShuffleSequence(data, chunks)
%
%           data    -  vector of values
%           chunks  -  the number of chunks to shuffle the data into
%
% $Id$

error(nargchk(2,2,nargin))

len         = length(data);
chunk_len   = floor(len / chunks);              % distance between chunks
chunk_ind   = (0:chunks-1) * chunk_len + 1;     % indexes o' chunks
chunk_ind   = chunk_ind(randperm(chunks));              % randomly permuted
out         = zeros(len,1);                     % output vector
offset      = 1;

for i = 1:chunks
    index   = chunk_ind(i);
    if index == max(chunk_ind)
        d   = data(index:end);
    else
        d   = data(index:index+chunk_len-1);
    end
    out(offset:offset+length(d)-1) = d;
    offset = offset+length(d);
end