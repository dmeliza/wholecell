function s1 = SparseS0ToS1(s0)
%
% Loads a file containing an s0 structure defining a sparse noise
% sequence, converting it into an s1 structure.
%
% [s1] = SparseS0toS1(s0)
%
% s0 can be a structure or the name of a file.
%
% The sparse noise structure is lacking several fields, which are supplied,
% and the s0.parameters field must be converted to the single-parameter
% vector used in the s1 structure.  Unfortunately one of the more critical
% static parameters is not present in the s0 file, so we have to derive this
% from the s0.stimulus field
%
% $Id$

error(nargchk(1,1,nargin))

s1  = s1_struct;
if ~isstruct(s0)
    s0  = load('-mat',s0);         % try to load the file
end
if isfield(s0,'colmap') & isfield(s0,'stimulus') & isfield(s0,'parameters')
    s1.mfile    = 'SparseFrame';
    s1.colmap   = s0.colmap;
    [x y z]     = size(s0.stimulus);
    s1.x_res    = x;
    s1.y_res    = y;
    frame       = s0.stimulus(:,:,1);       % the first frame
    [d p]     = getdims(frame);
    s1.static   = {d, [p]};
    
    param       = sub2ind(d, s0.parameters(:,1), s0.parameters(:,2));
    sign        = s0.parameters(:,3);
    s1.param    = sign .* param - ~sign .* param;
else
    error('Unable to load .s0 file');
end

function [d, p] = getdims(frame)
% tries to figure out the static parameters that generated the frame
m   = median(median(frame));        % find the background
i   = find(frame~=m);
p   = sqrt(length(i));                      % better be a square number
if fix(p) ~= p
    error('Unable to determine static parameters of stimulus');
end
d   = size(frame);
d   = d - p + 1;
