function [pre_rf, post_rf] = SpatialRF(pre, post, induction)
%
% Generates a figure comparing two spatial RFs (either two cells or
% before/after).
%
% [pre_rf, post_rf] = SPATIALRF(pre, post, [induction])
%
% pre and post can be matfiles or directories.  If directories, all the
% daqdata-?.r0 files will be loaded, and the individual trials used to
% generate error bars on the final plot (although these are usually quite
% small)
%
% The spatial RF is defined as the average of the 20 ms on either side of
% the maximum response.
%
% $Id$
global SPATIALRF_WIN
SPATIALRF_WIN     = [1000 6000];      % analysis window
SZ      = [3.0 3.0];
RFWIN   = 20;

types   = [exist(pre) exist(post)];
if all(types==7)
    [A,t,u] = loadFiles(pre);
    B       = loadFiles(post);
    a       = combineEpisodes(A);
    b       = combineEpisodes(B);
else
    A   = load(pre);
    B   = load(post);
    win     = SPATIALRF_WIN(1):SPATIALRF_WIN(2);
    t   = double(A.time(win,:)) * 1000 - 200;
    a   = double(A.data(win,:));
    b   = double(B.data(win,:));
    u   = A.units;
end

Fs  = mean(diff(t));
abase   = mean(mean(a(1:200,:)));
bbase   = mean(mean(b(1:200,:)));
a   = a - abase;
b   = b - bbase;

[mx i]  = max(abs(a));
[mx j]  = max(mx);
i       = i(j);

w       = fix(RFWIN/Fs);
I       = (-w:w) + i;
arf     = a(I,:);
brf     = b(I,:);


pre_rf     = mean(arf,1);
post_rf    = mean(brf,1);
switch lower(u)
    case {'pa','na'}
        pre_rf = -pre_rf;
        post_rf = -post_rf;
end

% compute error bars
if iscell(A)
    pre_err     = computeError(A,I,abase);
    post_err    = computeError(B,I,bbase);
end

f       = figure;
set(f,'color',[1 1 1]);
ResizeFigure(f,SZ);
hold on

X       = 1:length(pre_rf);
if iscell(A)
    p(1:2) = errorbar(X,pre_rf, pre_err, 'k');
    p(3:4) = errorbar(X,post_rf, post_err, 'r');
else
    p       = plot(X,pre_rf,'k',X,post_rf,'r');
end
set(p,'LineWidth',2);

set(gca,'XTick',X, 'XLim', [X(1) - 0.2, X(4) + 0.2],'Box','On')
xlabel('Bar Position')
ylabel('Response (pA)')
if nargin > 2
    hold on
    mx  = max([pre_rf(induction) post_rf(induction)]);
    h   = plot(induction, mx * 1.2, 'kv');
    set(h,'MarkerFaceColor',[0 0 0])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [d,t,u] = loadFiles(directory)
global SPATIALRF_WIN
win     = SPATIALRF_WIN(1):SPATIALRF_WIN(2);
wd      = cd(directory);
dd      = dir('*.r0');
fls     = {dd.name};
for i = 1:length(fls)
    r0       = load('-mat',fls{i});
    d{i}     = double(r0.r0.data(win,:,1));
end
t       = double(r0.r0.time(win,:)) * 1000 - 200;
u       = r0.r0.y_unit{1};
cd(wd)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function m  = combineEpisodes(in)
% turns a cell array into a double array by averaging along dim 2
for i = 1:length(in)
    m(:,i)  = mean(in{i},2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function e = computeError(in, win, base)
% computes the standard error of the mean value in the window
for i = 1:length(in)
    d       = in{i};
    d       = d(win,:) - base;
    tc      = mean(d,2);                    % time course of mean
    e(i)    = std(tc)/sqrt(length(tc));
end