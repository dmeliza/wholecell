function [] = SpatialRF(pre, post, induction)
%
% Generates a figure displaying the spatial RF of the cell, with the option
% of comparing it to another RF (e.g. post-induction)
%
% The spatial RF is defined as the average of the 20 ms on either side of
% the maximum response.
%
% $Id$
SZ      = [3.5 3.5];
WIN     = [1000:6000];      % analysis window
RFWIN   = 20;


A   = load(pre);
B   = load(post);

t   = double(A.time(WIN,:)) * 1000 - 200;
a   = double(A.data(WIN,:));
b   = double(B.data(WIN,:));
Fs  = mean(diff(t));

[mx i]  = max(abs(zscore(a)));
[mx j]  = max(mx);
i       = i(j);

w       = fix(RFWIN/Fs);
I       = (-w:w) + i;
arf     = a(I,:);
brf     = b(I,:);
abase   = mean(mean(a(1:200,:)));
bbase   = mean(mean(b(1:200,:)));

pre_rf     = mean(arf,1) - abase;
post_rf    = mean(brf,1) - bbase;
switch lower(A.units)
    case {'pa','na'}
        pre_rf = -pre_rf;
        post_rf = -post_rf;
end

f       = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,SZ);

X       = 1:length(pre_rf);
p       = plot(X,pre_rf,'k',X,post_rf,'r');
set(p,'LineWidth',2);
set(gca,'XTick',X, 'XLim', [X(1) - 0.2, X(4) + 0.2])
xlabel('Bar Position')
ylabel('Response (pA)')
if nargin > 2
    hold on
    mx  = max([pre_rf(induction) post_rf(induction)]);
    h   = plot(induction, mx * 1.2, 'kv');
    set(h,'MarkerFaceColor',[0 0 0])
end

% ind     = repmat((-RFWIN/Fs:RFWIN/Fs)',1, size(a,2));
% arf     = A(ind+i);
% brf     = B(ind+i);
%   = ((t(i)-20):Fs:(t(i)+20))';
%keyboard