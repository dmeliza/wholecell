function binneddata = BinData(data, binfactor)
% Bins data in a 2-dim matrix arranged columnwise into bins of binfactor columns
% For example: Matrix A is:
% [1 2 3 4]
% [2 3 4 5]
% [5 6 7 8]
% then BinData(A,2) gives
% [1.5 3.5]
% [2.5 4.5]
% [5.5 7.5]
%
% note that incomplete bins are discarded, so pick a binfactor as close
% as possible to a factor of size(data, 2)
%
% 1.3 - now attempts to detect if the input is a column
%
% $Id$

lT = size(data, 2);
if lT == 1 % data is probably columnwise
    data = shiftdim(data, 1);
    lT = size(data,2);
end
traceCount = fix(lT / binfactor); % throws away modulus
lT = traceCount * binfactor;

% reshape method
nd = reshape(data(:,1:lT),size(data,1), binfactor, traceCount);
binneddata = squeeze(mean(nd,2));

% iterative method
% binneddata = zeros(size(data,1), traceCount);
% for i = 1:traceCount
%     o = i*binfactor;
%     d = data(:,o:(o+binfactor));
%     binneddata(:,i) = mean(d,2);
% end
    
