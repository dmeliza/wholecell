function out = FrameShift(y, timing, window)
%
% Generates a frame-shifted matrix from a vector.  Each row in the vector
% will contain a subset of the vector beginning at a particular offset.
%
% out = FrameShift(y, timing, window)
% out = FrameShift(y, timings, window)
%
% y         - Nx1 input vector
% timing    - If a scalar, each row will be frame-shifted by a fixed amount
% timings   - Mx1 vector defining the start points (indices) for each row
% window    - J number of points per row
%
% out       - MxN array
%
% $Id$

% Check input dimensions etc
error(nargchk(3,3,nargin))
[len cols] = size(y);
[M X] = size(timing);
if cols > 1
    error('Input must be a single column vector');
elseif X > 1
    error('timing must be a scalar or a column vector');
end

if M == 1
    % equal chunk mode
    rows = len / timing;    % number of chunks
    cols = window;          % length of each chunk
    FRAMES = floor(len / timing - cols / timing);  % maximum number of frames
    out = zeros(FRAMES, cols);
    for i = 1:FRAMES
        ind = (i - 1) * timing;
        out(i,:) = y(ind+1:ind+cols)';
    end
else
    % index mode
    mx_ind = len - window - 1; % the maximum index supported by the input matrix
    ind = find(timing > mx_ind);
    if ~isempty(ind)
        %error(['Timing vector cannot contain values greater than ' num2str(mx_ind)]);
        mx = min(ind);
        timing = timing(1:mx-1);
        M = length(timing);
        warning(['Timing vector truncated to ' num2str(M) ' elements.']);
    end
    rows = M;
    cols = window;
    out = zeros(rows, cols);
    for i = 1:rows
        ind = timing(i)-1;
        out(i,:) = y(ind+1:ind+cols)';
    end
end