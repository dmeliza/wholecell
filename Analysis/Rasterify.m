function out = Rasterify(in, thresh)
%
% This function attempts to "deconvolve" an intracellular trace
% into a series of events of varying magnitude.  It does this by looking
% for significant movements away from the baseline.  Works best with
% cleanish data.  Multiple data sets should be arranged in columns
%
% $Id$
THRESH  = 2;
NORM    = [1:10];
if nargin < 2
    thresh = THRESH;
end

out = zeros(size(in));
A   = in;           % base data set
D   = diff(in);     % first derivative
C   = zeros(1,size(A,2)); % this row of zeros is used frequently
ZA  = zscore(A);
ZD  = zscore(D);
ZD  = [C; ZD];

R   = ((ZA > thresh) & (ZD > thresh)) | ((ZA < -thresh) & (ZD < -thresh));
ini = [R; C] & ~[~C; R];     % find initial ones in each region
fin = [C; R] & ~[R; ~C];     % find final ones

I   = find(ini(1:end-1,:));
F   = find(fin(2:end,:));

%A   = A - repmat(mean(A(NORM,:),1),size(A,1),1);
len     = size(A,1);
[i,j]   = ind2sub(size(A),I);
ip      = i - 1 + (i < 1);
i       = i + 1;
i(i>len) = deal(len);
%i       = i .* (i <= len) + (i > len) * len;
i(i>len) = deal(len);
I       = sub2ind(size(A),i,j);
J       = sub2ind(size(A),ip,j);
out(I)= A(I) - A(J);
%out(I) = A(I);


% These should be the same length
% I   = find(ini(1:end-1));
% F   = find(fin(2:end));
% for i = 1:length(I)
%     V   = max(abs(