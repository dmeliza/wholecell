function [AB, BA, M] = MatchMatrix(A, B)
%
% MATCHMATRIX - A more generalized find function.  Given two input vectors,
% A and B, finds the number of times each entry in A occurs in B, and vice
% versa.  Unlike FIND, what MATCHMATRIX returns is a weighting function.
% For example:
%
% A = [3 1 1], B = [1 1 4 3]
%
% the match matrix will be:
%
%      [3 1 1]
%   [1 [0 1 1
%    1  0 1 1
%    4  0 0 0
%    3] 1 0 0]
%
% [AB, BA, M] = MATCHMATRIX(A, B)
%
% AB is the weighting function for A in B (e.g. [2 2 0 1])
% BA is the weighting function for B in A (e.g. [1 2 2]
% M is the match matrix.
%
% $Id$

error(nargchk(2,2,nargin))

% fix dimensions
A   = A(:)';
B   = B(:);

% create matrices
AA  = repmat(A,size(B,1),1);
BB  = repmat(B,1,size(A,2));

M   = AA == BB;
AB  = sum(M,2);
BA  = sum(M,1);