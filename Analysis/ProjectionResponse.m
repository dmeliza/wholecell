function [X,P] = projectionresponse(y, y_est, bin_num)
% Computes the projection-response histogram for y_est (projection) against y (response)
% Bins are normalized (-1 is maximum negative projection, +1 maximum positive)
% [x,p] = project(y, y_est, [bins])
% y - the response (column vector)
% y_est - the projection (column vector)
% bins - the number of bins (default 10)
% x - the bin centers (-0.9 to +0.9)
% p - the average y value for y_est = x
% is there a good way to do this without a loop?
%
% $Id$

% check argument count
error(nargchk(2,3,nargin));

% check size of inputs
if size(y,2) > 1 | size(y_est,2) > 1
    error('y and y_est must be column vectors.');
elseif length(y) ~= length(y_est)
    error('y and y_est must have the same length');
end

% setup bins
if nargin < 3
    bin_num = 10;
end
mn = min(y_est);
mx = max(y_est);
bins = (mn:(mx-mn)/bin_num:mx)';
X = (-1:2/bin_num:+1)';

% Fill the bins (lower edge inclusive)
[P,N] = deal(zeros(length(X)-1,1));
for i = 1:(length(X)-1)
    j = find(y_est>=bins(i) & y_est<bins(i+1)); % indexes of points in that bin
    if i == length(X)-1
        j = cat(1,j,find(y_est==bins(i+1)));
    end
    P(i) = sum(y(j));
    N(i) = length(j);
end

% calculate bin centers
X = X(1:end-1) + diff(X)/2;
% normalize projection to the number of points in each bin
P = P./N;